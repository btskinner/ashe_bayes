#!/usr/local/bin/bash

# ==============================================================================
# SET OPTIONS
# ==============================================================================

usage()
{
    cat <<EOF
 
 PURPOSE:
 This script knits and builds jekyll website.
 
 USAGE: 
 $0 <arguments>
 
 ARGUMENTS:
    [-m]        Module to knit (w/o ending)
    [-b]        Build site w/o knitting module
    [-i]        Directory of module *.Rmd files
    [-o]        Directory where pdf versions of modules should go
    [-s]        Directory where purled scripts files should go
    [-d]        Development version of site (local *_dev)
    [-c]        Output directory for course assignments, data, modules, and scripts
    [-v]        Render / build verbosely (optional flag)

 EXAMPLES:
 
 ./kbuild.sh -m all
 ./kbuild.sh -m intro
 ./kbuild.sh -m all -i _modules -d
 ./kbuild.sh -b 

 DEFAULT VALUES:

 i = _modules
 o = modules
 s = scripts
 c = ../<dir name>_participant
 d = 0 (create actual site)
 b = 0 (nothing)
 v = 0 (knit/build quietly)

EOF
}

# defaults
i="_modules"
oi=$i
o="modules"
s="scripts"
d=0
b=0
c=0
v=0

knit_q="TRUE"
build_q="--quiet"
participant_repo="../${PWD##*/}_participant"
pdfs="assets/pdf"
build_site=0

# pandoc
pandoc_opts="-V geometry:margin=1in --highlight-style tango --pdf-engine=xelatex --variable monofont=\"Menlo\" -f markdown-implicit_figures "
pandoc_opts+="-V colorlinks=true -V linkcolor=blue -V urlcolor=blue -V links-as-notes -H head.tex"

# sed
sed_opts_1="s/\/bayes_workshop\/assets/..\/assets/g; s/\/bayes_workshop\/modules/..\/modules/g; s/\/bayes_workshop\/figures/..\/figures/g;"
sed_opts_2="s/..\/assets/.\/assets/g; s/..\/modules/https:\/btskinner.io\/bayes_workshop\/modules/g; s/<img src=\"\(\.\.\/figures\/.*\.png\)\".* width=\"100%\" \/>/\!\[\]\(${i}\/\1\)/g"

while getopts "hm:i:o:s:dbcv" opt;
do
    case $opt in
	h)
	    usage
	    exit 1
	    ;;
	m)
	    l=$OPTARG 
	    ;;
	i)
	    i=$OPTARG
	    ;;
	o)
	    o=$OPTARG
	    ;;
	s)
	    s=$OPTARG
	    ;;
	d)
	    d=1
	    ;;
	b)
	    b=1
	    ;;
	c)
	    c=1
	    ;;
	v)
	    v=1
	    ;;
	\?)
	    usage
	    exit 1
	    ;;
    esac
done

# flags for knitting
! [[ -z "$m" ]] && knit_modules=1 || knit_modules=0

# change quiet options if verbose flag is chosen
if [[ $v == 1 ]]; then
    knit_q="FALSE"
    build_q=""
fi

# set paths for site build location
if [[ $d == 1 ]]; then
    config_yml="./_config_dev.yml"
    site_path="./_site_dev"
else
    config_yml="./_config.yml"
    site_path="./_site"
fi

# turn on build site
if [[ $b == 1 ]]; then
    build_site=1
fi

printf "\nKNIT RMARKDOWN / BUILD JEKYLL SITE\n"
printf -- "----------------------------------\n"

# ==============================================================================
# PRINT OPTIONS
# ==============================================================================

printf "\n[ Options ]\n\n"

if [[ $m == "all" ]]; then
    which_modules="all *.Rmd files"
else
    which_modules="${m}.Rmd"
fi

if [[ $knit_modules == 1 ]]; then
    printf "  Knitting: modules                  = %s\n" "$which_modules"
    printf "  Modules *.Rmd input directory      = %s\n" "$i"
    printf "  Modules *.Rmd output directory     = %s\n" "$o"
fi

if [[ $c == 1 ]]; then
    printf "  Participant files directory            = %s\n" "$participant_repo"
fi

# ==============================================================================
# KNIT
# ==============================================================================

# ------------------
# modules
# ------------------

if [[ $knit_modules == 1 ]]; then
    printf "\n[ Knitting and purling modules... ]\n\n"
    if [[ $m != "all" ]]; then
	printf "  $m.Rmd ==> \n"
	f="$i/$m.Rmd"
	# skip if starts with underscore
	if [[ $m = _* ]]; then
	    printf "     skipping...\n"
	else
	    # knit
	    Rscript -e "knitr::knit('$f', output='$oi/$m.md', quiet = $knit_q)" 2>&1 > /dev/null
	    # fix path for local build
	    sed -i '' "${sed_opts_1}" $oi/$m.md
	    printf "     $oi/$m.md\n"
	    # md to pdf
	    if [[ -f $oi/$m.md ]]; then
		sed "${sed_opts_2}" $oi/$m.md | pandoc ${pandoc_opts} -o $o/$m.pdf -
		cp $o/$m.pdf $pdfs
	    fi
	    # purl
	    Rscript -e "knitr::purl('$f', documentation = 0, quiet = $knit_q)" 2>&1 > /dev/null
	    printf "     $s/$l.R\n"
	    # more than one line after removing \n? mv to scripts directory : rm
	    [[ $(tr -d '\n' < ${l}.R | wc -c) -ge 1 ]] && mv ${l}.R $s/${l}.R || rm ${l}.R
	fi
    else 
	for file in ${i}/*.Rmd
	do
	    # get file name without ending
	    f=$(basename "${file%.*}")
	    printf "  $f.Rmd ==> \n"
	    # skip if starts with underscore
	    if [[ $f = _* ]]; then printf "     skipping...\n"; continue; fi
	    # knit
	    Rscript -e "knitr::knit('$file', output='$oi/$f.md', quiet = $knit_q)" 2>&1 > /dev/null
	    # fix path for local build
	    sed -i '' "${sed_opts_1}" $oi/$f.md
	    printf "     $oi/$f.md\n"
	    # md to pdf
	    if [[ -f $oi/$f.md ]]; then
		sed "${sed_opts_2}" $oi/$f.md | pandoc ${pandoc_opts} -o $o/$f.pdf -
		cp $o/$f.pdf $pdfs
	    fi
	    # purl
	    Rscript -e "knitr::purl('$file', documentation = 0, quiet = $knit_q)" 2>&1 > /dev/null
	    printf "     $s/$f.R\n"
	    # more than one line after removing \n? mv to scripts directory : rm
	    [[ $(tr -d '\n' < ${f}.R | wc -c) -ge 1 ]] && mv ${f}.R $s/${f}.R || rm ${f}.R
	done
    fi
fi

# ==============================================================================
# BUILD
# ==============================================================================

if [[ $knit_modules == 1 ]] || [[ $build_site == 1 ]]; then
    printf "\n[ Building... ]\n\n"
    bundle exec jekyll build $build_q --config $config_yml --destination $site_path --verbose 2>/dev/null
    printf "  Built site ==>\n"
    printf "     config file:   $config_yml\n"
    printf "     location:      $site_path\n"
fi

# ==============================================================================
# MOVE FILES TO PARTICIPANT REPO
# ==============================================================================

if [ $c == 1 ]; then
    printf "\n[ Copying files for participant repos... ]\n\n"
    # make directory if it doesn't exist
    mkdir -p $participant_repo/data $participant_repo/modules
    # move files
    printf "  - README.md\n"
    cp _participant_README.md $participant_repo/README.md
    printf "  - .gitignore\n"
    cp .participant_gitignore $participant_repo/.gitignore
    printf "  - Data\n"
    cp -r data $participant_repo
    printf "  - Modules\n"
    cp modules/README.md $participant_repo/modules/README.md
    cp modules/*.pdf $participant_repo/modules
    printf "  - Scripts\n"
    cp -r scripts $participant_repo
fi

# ==============================================================================
# FINISH
# ==============================================================================

printf "\n[ Finished! ]\n\n"

# ==============================================================================
