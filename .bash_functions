
mongo_shell()
{
  type heroku >/dev/null 2>&1
  has_heroku=$([ $? -eq 0 ] && echo 1 || echo 0)

  if [ ${1:+set} ]; then 
    url=$1
  elif [ ${MONGOHQ_URL:+set} ]; then
    url="$MONGOHQ_URL"
  elif [ -d app ] && [ $has_heroku -eq 1 ]; then
    url=$(heroku config --long |grep MONGOHQ_URL | awk '{print$3}')
  else
    echo "Missing mongodb url" 1>&2
    return 1
  fi

  set -- $(ruby -r uri -e 'u=URI.parse(ARGV[0])
    puts u.host||"localhost"
    puts u.port||27017
    puts u.path||"/adaptly_development"
    puts u.user
    puts u.password' $url)
  if [ ! -z $4 ] && [ ! -z $5 ]; then
    mongo $1:$2$3 -u "$4" -p "$5"
  elif [ ! -z $4 ]; then
    mongo $1:$2$3 -u "$4" 
  elif [ ! -z $5 ]; then
    mongo $1:$2$3 -p "$5" 
  else
    mongo $1:$2$3
  fi

  return $?
}

rscreen() {
	session=${1:?Missing session}
	if [ ! -f Gemfile ]; then 
		echo "Not in a rails project" 1>&2 
		return 2
	fi
	screen -S $session vim
}

# Configure colors, if available.
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	c_reset='\[\e[0m\]'
	c_user='\[\033[0;32m\]'
	c_path='\[\e[0;33m\]'
	c_git_clean='\[\e[0;36m\]'
	c_git_dirty='\[\e[0;35m\]'
else
	c_reset=
	c_user=
	c_path=
	c_git_clean=
	c_git_dirty=
fi

type __git_ps1 >/dev/null 2>&1
export HAVE_GIT_PS1=$([[ $? -eq 0 ]] && echo 1 || echo 0)

set_ps1()
{
  if [[ ${VIM:+set} ]]; then
    vim="VIM-"
  fi

  if [ ${HAVE_GIT_PS1:-0} -eq 1 ]; then
    git=$(__git_ps1 " (%s)")
    #if [[ "$git" =~ [^-_.a-zA-Z0-9]\) ]]; then
    #fi
  fi

  if [ $USER = "root" ]; then
	  c_user='\[\033[0;31m\]'
  else
	  c_user='\[\033[0;32m\]'
  fi

  # PS1="\[\033[1;34m\]\u@\h:\w$\[\033[0m\] "
  if [[ $PWD =~ adaptly/[^/]*production ]]; then
	  c_path='\[\e[0;31m\]'
  elif [[ $PWD =~ adaptly/[^/]*staging ]]; then
	  c_path='\[\e[0;35m\]'
  elif [[ $PWD =~ adaptly/[^/]*test ]]; then
	  c_path='\[\e[0;36m\]'
  else
	  c_path='\[\e[0;37m\]'
  fi

  # Thy holy prompt.
  echo "${vim}${c_user}\h${c_reset}:${c_path}\w${c_reset}${git}\$ "
}
export PROMPT_COMMAND='PS1="$(set_ps1)"'
# vim:ft=sh
