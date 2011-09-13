# Configure colors, if available.
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	c_reset='\[\e[0m\]'
	c_user='\[\033[0;32m\]'
	c_path='\[\e[0;33m\]'
	c_git_clean='\[\e[0;36m\]'
	c_git_dirty='\[\e[0;34m\]'
else
	c_reset=
	c_user=
	c_path=
	c_git_clean=
	c_git_dirty=
fi

# Thy holy prompt.
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
    prompt='#'
  else
	  c_user='\[\033[0;32m\]'
    prompt='>'
  fi

  # PS1="\[\033[1;34m\]\u@\h:\w$\[\033[0m\] "
  if [[ $PWD =~ adaptly/[^/]*production ]]; then
	  c_path='\[\e[0;31m\]'
  elif [[ $PWD =~ adaptly/[^/]*staging ]]; then
	  c_path='\[\e[0;35m\]'
  elif [[ $PWD =~ adaptly/[^/]*t.st ]]; then
	  c_path='\[\e[0;36m\]'
  else
	  c_path='\[\e[0;37m\]'
  fi
  echo "${vim}${c_user}\h${c_reset}:${c_path}\w${c_reset}${git}${prompt} "
}
export PROMPT_COMMAND='PS1="$(set_ps1)"'
#export PROMPT_COMMAND='PS1="${c_user}\h${c_reset}:${c_path}\w${c_reset}$(set_ps1)\$ "'

m()
{
	echo "$*"
	eval $*
}

mongo_shell()
{
  type heroku >/dev/null 2>&1
  has_heroku=$([ $? -eq 0 ] && echo 1 || echo 0)

  if [ ${1:+set} ]; then 
    url=$1
  elif [ ${MONGOHQ_URL:+set} ]; then
    url="$MONGOHQ_URL"
  elif [ -d app ] && [ $has_heroku -eq 1 ]; then
		if [ `basename $PWD` = 'insightful' ]; then
			url=$(heroku config --long --app adaptly-insightful | grep MONGOHQ_URL | awk '{print$3}')
		else
    	url=$(heroku config --long --app `pwd -P | sed 's,.*/,,'`|grep MONGOHQ_URL | awk '{print$3}')
		fi
  else
		url=$( printf "mongodb://localhost:27017/%s"  `rails runner 'puts "#{Rails.root.basename.to_s}_#{Rails.env}"' |tail -1`)
    #echo "Missing mongodb url" 1>&2
    #return 1
  fi

	echo using mongo url $url
  set -- $(ruby -r uri -e 'u=URI.parse(ARGV[0])
    puts u.host||"localhost"
    puts u.port||27017
    puts u.path||"/adaptly_development"
    puts u.user
    puts u.password' $url)
  if [ ! -z $4 ] && [ ! -z $5 ]; then
    m mongo $1:$2$3 -u "$4" -p "$5"
  elif [ ! -z $4 ]; then
    m mongo $1:$2$3 -u "$4" 
  elif [ ! -z $5 ]; then
    m mongo $1:$2$3 -p "$5" 
  else
    m mongo $1:$2$3
  fi

  return $?
}

rscreen()
{
	session=${1:?Missing session}
	if [ ! -f Gemfile ]; then 
		echo "Not in a rails project" 1>&2 
		return 2
	fi
	/opt/local/bin/screen -S $session /opt/local/bin/vim
}

bundlecd()
{
  cd $(bundle show $*)
}

function gemcd
{
  cd $(dirname `gem which $*`)
}
# vim:ft=sh
