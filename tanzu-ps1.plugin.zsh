#!/usr/bin/env bash

# Tanzu CLI prompt helper for bash/zsh
# Displays current project and space

#  Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Original code for kube-ps1 by Jon Mosco
# Modifications adapting for Tanzu CLI by Brian Kirkland


# Debug
[[ -n $DEBUG ]] && set -x

# Default values for the prompt
# Override these values in ~/.zshrc or ~/.bashrc
TANZU_PS1_BINARY="${TANZU_PS1_BINARY:-tanzu}"
TANZU_PS1_SYMBOL_ENABLE="${TANZU_PS1_SYMBOL_ENABLE:-true}"
TANZU_PS1_SYMBOL_DEFAULT=${TANZU_PS1_SYMBOL_DEFAULT:-$'TZ'}
TANZU_PS1_SYMBOL_PADDING="${TANZU_PS1_SYMBOL_PADDING:-false}"
TANZU_PS1_SYMBOL_USE_IMG="${TANZU_PS1_SYMBOL_USE_IMG:-false}"
TANZU_PS1_SPACE_ENABLE="${TANZU_PS1_SPACE_ENABLE:-true}"
TANZU_PS1_PROJECT_ENABLE="${TANZU_PS1_PROJECT_ENABLE:-true}"
TANZU_PS1_PREFIX="${TANZU_PS1_PREFIX-(}"
TANZU_PS1_SEPARATOR="${TANZU_PS1_SEPARATOR-|}"
TANZU_PS1_DIVIDER="${TANZU_PS1_DIVIDER-:}"
TANZU_PS1_SUFFIX="${TANZU_PS1_SUFFIX-)}"

TANZU_PS1_SYMBOL_COLOR="${TANZU_PS1_SYMBOL_COLOR-green}"
TANZU_PS1_PROJECT_COLOR="${TANZU_PS1_PROJECT_COLOR-red}"
TANZU_PS1_SPACE_COLOR="${TANZU_PS1_SPACE_COLOR-cyan}"
TANZU_PS1_BG_COLOR="${TANZU_PS1_BG_COLOR}"

TANZU_PS1_TANZUCONFIG_CACHE="${TANZUCONFIG}"
TANZU_PS1_TANZUCONFIG_SYMLINK="${TANZU_PS1_TANZUCONFIG_SYMLINK:-false}"
TANZU_PS1_DISABLE_PATH="${HOME}/.kube/tanzu-ps1/disabled"
TANZU_PS1_LAST_TIME=0
TANZU_PS1_CLUSTER_FUNCTION="${TANZU_PS1_CLUSTER_FUNCTION}"
TANZU_PS1_SPACE_FUNCTION="${TANZU_PS1_SPACE_FUNCTION}"

# Determine our shell
if [ "${ZSH_VERSION-}" ]; then
  TANZU_PS1_SHELL="zsh"
elif [ "${BASH_VERSION-}" ]; then
  TANZU_PS1_SHELL="bash"
fi

_TANZU_PS1_init() {
  [[ -f "${TANZU_PS1_DISABLE_PATH}" ]] && TANZU_PS1_ENABLED=off

  case "${TANZU_PS1_SHELL}" in
    "zsh")
      _TANZU_PS1_OPEN_ESC="%{"
      _TANZU_PS1_CLOSE_ESC="%}"
      _TANZU_PS1_DEFAULT_BG="%k"
      _TANZU_PS1_DEFAULT_FG="%f"
      setopt PROMPT_SUBST
      autoload -U add-zsh-hook
      add-zsh-hook precmd _TANZU_PS1_update_cache
      zmodload -F zsh/stat b:zstat
      zmodload zsh/datetime
      ;;
    "bash")
      _TANZU_PS1_OPEN_ESC=$'\001'
      _TANZU_PS1_CLOSE_ESC=$'\002'
      _TANZU_PS1_DEFAULT_BG=$'\033[49m'
      _TANZU_PS1_DEFAULT_FG=$'\033[39m'
      [[ $PROMPT_COMMAND =~ _TANZU_PS1_update_cache ]] || PROMPT_COMMAND="_TANZU_PS1_update_cache;${PROMPT_COMMAND:-:}"
      ;;
  esac
}

_TANZU_PS1_color_fg() {
  local TANZU_PS1_FG_CODE
  case "${1}" in
    black) TANZU_PS1_FG_CODE=0;;
    red) TANZU_PS1_FG_CODE=1;;
    green) TANZU_PS1_FG_CODE=2;;
    yellow) TANZU_PS1_FG_CODE=3;;
    blue) TANZU_PS1_FG_CODE=4;;
    magenta) TANZU_PS1_FG_CODE=5;;
    cyan) TANZU_PS1_FG_CODE=6;;
    white) TANZU_PS1_FG_CODE=7;;
    # 256
    [0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-6]) TANZU_PS1_FG_CODE="${1}";;
    *) TANZU_PS1_FG_CODE=default
  esac

  if [[ "${TANZU_PS1_FG_CODE}" == "default" ]]; then
    TANZU_PS1_FG_CODE="${_TANZU_PS1_DEFAULT_FG}"
    return
  elif [[ "${TANZU_PS1_SHELL}" == "zsh" ]]; then
    TANZU_PS1_FG_CODE="%F{$TANZU_PS1_FG_CODE}"
  elif [[ "${TANZU_PS1_SHELL}" == "bash" ]]; then
    if tput setaf 1 &> /dev/null; then
      TANZU_PS1_FG_CODE="$(tput setaf ${TANZU_PS1_FG_CODE})"
    elif [[ $TANZU_PS1_FG_CODE -ge 0 ]] && [[ $TANZU_PS1_FG_CODE -le 256 ]]; then
      TANZU_PS1_FG_CODE="\033[38;5;${TANZU_PS1_FG_CODE}m"
    else
      TANZU_PS1_FG_CODE="${_TANZU_PS1_DEFAULT_FG}"
    fi
  fi
  echo ${_TANZU_PS1_OPEN_ESC}${TANZU_PS1_FG_CODE}${_TANZU_PS1_CLOSE_ESC}
}

_TANZU_PS1_color_bg() {
  local TANZU_PS1_BG_CODE
  case "${1}" in
    black) TANZU_PS1_BG_CODE=0;;
    red) TANZU_PS1_BG_CODE=1;;
    green) TANZU_PS1_BG_CODE=2;;
    yellow) TANZU_PS1_BG_CODE=3;;
    blue) TANZU_PS1_BG_CODE=4;;
    magenta) TANZU_PS1_BG_CODE=5;;
    cyan) TANZU_PS1_BG_CODE=6;;
    white) TANZU_PS1_BG_CODE=7;;
    # 256
    [0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-6]) TANZU_PS1_BG_CODE="${1}";;
    *) TANZU_PS1_BG_CODE=$'\033[0m';;
  esac

  if [[ "${TANZU_PS1_BG_CODE}" == "default" ]]; then
    TANZU_PS1_FG_CODE="${_TANZU_PS1_DEFAULT_BG}"
    return
  elif [[ "${TANZU_PS1_SHELL}" == "zsh" ]]; then
    TANZU_PS1_BG_CODE="%K{$TANZU_PS1_BG_CODE}"
  elif [[ "${TANZU_PS1_SHELL}" == "bash" ]]; then
    if tput setaf 1 &> /dev/null; then
      TANZU_PS1_BG_CODE="$(tput setab ${TANZU_PS1_BG_CODE})"
    elif [[ $TANZU_PS1_BG_CODE -ge 0 ]] && [[ $TANZU_PS1_BG_CODE -le 256 ]]; then
      TANZU_PS1_BG_CODE="\033[48;5;${TANZU_PS1_BG_CODE}m"
    else
      TANZU_PS1_BG_CODE="${DEFAULT_BG}"
    fi
  fi
  echo ${OPEN_ESC}${TANZU_PS1_BG_CODE}${CLOSE_ESC}
}

_TANZU_PS1_binary_check() {
  command -v $1 >/dev/null
}

_TANZU_PS1_symbol() {
  [[ "${TANZU_PS1_SYMBOL_ENABLE}" == false ]] && return

  case "${TANZU_PS1_SHELL}" in
    bash)
      if ((BASH_VERSINFO[0] >= 4)) && [[ $'\u2388' != "\\u2388" ]]; then
        TANZU_PS1_SYMBOL="${TANZU_PS1_SYMBOL_DEFAULT}"
        TANZU_PS1_SYMBOL_IMG=$'\u2638\ufe0f'
      else
        TANZU_PS1_SYMBOL=$'\xE2\x8E\x88'
        TANZU_PS1_SYMBOL_IMG=$'\xE2\x98\xB8'
      fi
      ;;
    zsh)
      TANZU_PS1_SYMBOL="${TANZU_PS1_SYMBOL_DEFAULT}"
      TANZU_PS1_SYMBOL_IMG="\u2638";;
    *)
      TANZU_PS1_SYMBOL="k8s"
  esac

  if [[ "${TANZU_PS1_SYMBOL_USE_IMG}" == true ]]; then
    TANZU_PS1_SYMBOL="${TANZU_PS1_SYMBOL_IMG}"
  fi

  if [[ "${TANZU_PS1_SYMBOL_PADDING}" == true ]]; then
    echo "${TANZU_PS1_SYMBOL} "
  else
    echo "${TANZU_PS1_SYMBOL}"
  fi

}

_TANZU_PS1_split() {
  type setopt >/dev/null 2>&1 && setopt SH_WORD_SPLIT
  local IFS=$1
  echo $2
}

_TANZU_PS1_file_newer_than() {
  local mtime
  local file=$1
  local check_time=$2

  if [[ "${TANZU_PS1_TANZUCONFIG_SYMLINK}" == "true" ]]; then
    if [[ "${TANZU_PS1_SHELL}" == "zsh" ]]; then
      mtime=$(zstat -L +mtime "${file}")
    elif stat -c "%s" /dev/null &> /dev/null; then
      # GNU stat
      mtime=$(stat -c %Y "${file}")
    else
      # BSD stat
      mtime=$(stat -f %m "$file")
    fi
  else
    if [[ "${TANZU_PS1_SHELL}" == "zsh" ]]; then
      mtime=$(zstat +mtime "${file}")
    elif stat -c "%s" /dev/null &> /dev/null; then
      # GNU stat
      mtime=$(stat -L -c %Y "${file}")
    else
      # BSD stat
      mtime=$(stat -L -f %m "$file")
    fi
  fi

  [[ "${mtime}" -gt "${check_time}" ]]
}

_TANZU_PS1_update_cache() {
  local return_code=$?

  [[ "${TANZU_PS1_ENABLED}" == "off" ]] && return $return_code

  if ! _TANZU_PS1_binary_check "${TANZU_PS1_BINARY}"; then
    # No ability to fetch project/space; display N/A.
    TANZU_PS1_PROJECT="BINARY-N/A"
    TANZU_PS1_SPACE="N/A"
    return
  fi

  if [[ "${TANZUCONFIG}" != "${TANZU_PS1_TANZUCONFIG_CACHE}" ]]; then
    # User changed TANZUCONFIG; unconditionally refetch.
    TANZU_PS1_TANZUCONFIG_CACHE=${TANZUCONFIG}
    _TANZU_PS1_get_project_space
    return
  fi

  # read the environment variable $TANZUCONFIG
  # otherwise set it to ~/.config/tanzu/config-ng.yaml
  local conf
  for conf in $(_TANZU_PS1_split : "${TANZUCONFIG:-${HOME}/.config/tanzu/config-ng.yaml}"); do
    [[ -r "${conf}" ]] || continue
    if _TANZU_PS1_file_newer_than "${conf}" "${TANZU_PS1_LAST_TIME}"; then
      _TANZU_PS1_get_project_space
      return
    fi
  done

  return $return_code
}

_TANZU_PS1_get_project() {
  if [[ "${TANZU_PS1_PROJECT_ENABLE}" == true ]]; then
    context_info=$(yq eval ".contexts[] | select(.name == \"$(yq eval '.currentContext.tanzu' "${TANZUCONFIG:-${HOME}/.config/tanzu/config-ng.yaml}")\") | .additionalMetadata" "${TANZUCONFIG:-${HOME}/.config/tanzu/config-ng.yaml}")
    TANZU_PS1_PROJECT="$(echo "$context_info" | yq eval '.tanzuProjectName' -)"
    # Set namespace to 'N/A' if it is not defined
    TANZU_PS1_PROJECT="${TANZU_PS1_PROJECT:-N/A}"

    if [[ ! -z "${TANZU_PS1_PROJECT_FUNCTION}" ]]; then
      TANZU_PS1_PROJECT=$($TANZU_PS1_PROJECT_FUNCTION $TANZU_PS1_PROJECT)
    fi
  fi
}

_TANZU_PS1_get_space() {
  if [[ "${TANZU_PS1_SPACE_ENABLE}" == true ]]; then
    context_info=$(yq eval ".contexts[] | select(.name == \"$(yq eval '.currentContext.tanzu' "${TANZUCONFIG:-${HOME}/.config/tanzu/config-ng.yaml}")\") | .additionalMetadata" "${TANZUCONFIG:-${HOME}/.config/tanzu/config-ng.yaml}")
    TANZU_PS1_SPACE="$(echo "$context_info" | yq eval '.tanzuSpaceName' -)"
    # Set namespace to 'default' if it is not defined
    TANZU_PS1_SPACE="${TANZU_PS1_SPACE:-default}"

    if [[ ! -z "${TANZU_PS1_SPACE_FUNCTION}" ]]; then
        TANZU_PS1_SPACE=$($TANZU_PS1_SPACE_FUNCTION $TANZU_PS1_SPACE)
    fi
  fi
}

_TANZU_PS1_get_project_space() {
  # Set the command time
  if [[ "${TANZU_PS1_SHELL}" == "bash" ]]; then
    if ((BASH_VERSINFO[0] >= 4 && BASH_VERSINFO[1] >= 2)); then
      TANZU_PS1_LAST_TIME=$(printf '%(%s)T')
    else
      TANZU_PS1_LAST_TIME=$(date +%s)
    fi
  elif [[ "${TANZU_PS1_SHELL}" == "zsh" ]]; then
    TANZU_PS1_LAST_TIME=$EPOCHSECONDS
  fi

  _TANZU_PS1_get_project
  _TANZU_PS1_get_space
}

# Set tanzu-ps1 shell defaults
_TANZU_PS1_init

_tanzuon_usage() {
  cat <<"EOF"
Toggle tanzu-ps1 prompt on

Usage: tanzuon [-g | --global] [-h | --help]

With no arguments, turn off tanzu-ps1 status for this shell instance (default).

  -g --global  turn on tanzu-ps1 status globally
  -h --help    print this message
EOF
}

_tanzuoff_usage() {
  cat <<"EOF"
Toggle tanzu-ps1 prompt off

Usage: tanzuoff [-g | --global] [-h | --help]

With no arguments, turn off tanzu-ps1 status for this shell instance (default).

  -g --global turn off tanzu-ps1 status globally
  -h --help   print this message
EOF
}

tanzuon() {
  if [[ "${1}" == '-h' || "${1}" == '--help' ]]; then
    _tanzuon_usage
  elif [[ "${1}" == '-g' || "${1}" == '--global' ]]; then
    rm -f -- "${TANZU_PS1_DISABLE_PATH}"
  elif [[ "$#" -ne 0 ]]; then
    echo -e "error: unrecognized flag ${1}\\n"
    _tanzuon_usage
    return
  fi

  TANZU_PS1_ENABLED=on
}

tanzuoff() {
  if [[ "${1}" == '-h' || "${1}" == '--help' ]]; then
    _tanzuoff_usage
  elif [[ "${1}" == '-g' || "${1}" == '--global' ]]; then
    mkdir -p -- "$(dirname "${TANZU_PS1_DISABLE_PATH}")"
    touch -- "${TANZU_PS1_DISABLE_PATH}"
  elif [[ $# -ne 0 ]]; then
    echo "error: unrecognized flag ${1}" >&2
    _tanzuoff_usage
    return
  fi

  TANZU_PS1_ENABLED=off
}

# Build our prompt
tanzu_ps1() {
  [[ "${TANZU_PS1_ENABLED}" == "off" ]] && return
  [[ -z "${TANZU_PS1_PROJECT}" ]] && [[ "${TANZU_PS1_PROJECT_ENABLE}" == true ]] && return

  local TANZU_PS1
  local TANZU_PS1_RESET_COLOR="${_TANZU_PS1_OPEN_ESC}${_TANZU_PS1_DEFAULT_FG}${_TANZU_PS1_CLOSE_ESC}"

  # Background Color
  [[ -n "${TANZU_PS1_BG_COLOR}" ]] && TANZU_PS1+="$(_TANZU_PS1_color_bg ${TANZU_PS1_BG_COLOR})"

  # Prefix
  if [[ -z "${TANZU_PS1_PREFIX_COLOR:-}" ]] && [[ -n "${TANZU_PS1_PREFIX}" ]]; then
      TANZU_PS1+="${TANZU_PS1_PREFIX}"
  else
      TANZU_PS1+="$(_TANZU_PS1_color_fg $TANZU_PS1_PREFIX_COLOR)${TANZU_PS1_PREFIX}${TANZU_PS1_RESET_COLOR}"
  fi

  # Symbol
  TANZU_PS1+="$(_TANZU_PS1_color_fg $TANZU_PS1_SYMBOL_COLOR)$(_TANZU_PS1_symbol)${TANZU_PS1_RESET_COLOR}"

  if [[ -n "${TANZU_PS1_SEPARATOR}" ]] && [[ "${TANZU_PS1_SYMBOL_ENABLE}" == true ]]; then
    TANZU_PS1+="${TANZU_PS1_SEPARATOR}"
  fi

  # Context
  if [[ "${TANZU_PS1_PROJECT_ENABLE}" == true ]]; then
    TANZU_PS1+="$(_TANZU_PS1_color_fg $TANZU_PS1_PROJECT_COLOR)${TANZU_PS1_PROJECT}${TANZU_PS1_RESET_COLOR}"
  fi

  # Namespace
  if [[ "${TANZU_PS1_SPACE_ENABLE}" == true ]]; then
    if [[ -n "${TANZU_PS1_DIVIDER}" ]] && [[ "${TANZU_PS1_PROJECT_ENABLE}" == true ]]; then
      TANZU_PS1+="${TANZU_PS1_DIVIDER}"
    fi
    TANZU_PS1+="$(_TANZU_PS1_color_fg ${TANZU_PS1_SPACE_COLOR})${TANZU_PS1_SPACE}${TANZU_PS1_RESET_COLOR}"
  fi

  # Suffix
  if [[ -z "${TANZU_PS1_SUFFIX_COLOR:-}" ]] && [[ -n "${TANZU_PS1_SUFFIX}" ]]; then
      TANZU_PS1+="${TANZU_PS1_SUFFIX}"
  else
      TANZU_PS1+="$(_TANZU_PS1_color_fg $TANZU_PS1_SUFFIX_COLOR)${TANZU_PS1_SUFFIX}${TANZU_PS1_RESET_COLOR}"
  fi

  # Close Background color if defined
  [[ -n "${TANZU_PS1_BG_COLOR}" ]] && TANZU_PS1+="${_TANZU_PS1_OPEN_ESC}${_TANZU_PS1_DEFAULT_BG}${_TANZU_PS1_CLOSE_ESC}"

  echo "${TANZU_PS1}"
}
