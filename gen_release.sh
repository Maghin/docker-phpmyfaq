#!/bin/bash
# ----------------------------------------------------------------------
# Name: gen_release.sh
# Usage: bash gen-release.sh [VERSION] [--help] [--debug]
# ----------------------------------------------------------------------
# Author: Adrien Estanove <adrien.estanove@asr-informatique.fr>
# Version: 1.1
# Updated: 25 oct 2017
# ----------------------------------------------------------------------
# Required git config :
#   git config --add branch.master.remote origin
#   git config --add branch.master.merge dev
# ----------------------------------------------------------------------

# User Variables
DRY_RUN=yes # Comment this line to disable dry run mode
PKG_NAME="phpmyfaq" # Package or docker image name
DOCKER_REPO="merhylstudio" # registry[:port][/namespace]


# Function: msg_help
# ----------------------------------------------------------------------
# Print help message
msg_help() {
    echo -e "Usage: $0 [VERSION [--verbose]] | [--help]" 2>&1
    echo -e "\nParams:"
    echo -e "  VERSION              Set the version to tag and build, ex. \"0.1.2\""
    echo -e "\nOptions:"
    echo -e "  -p, --no-cache       Purge previous builds."
    echo -e "  -v, --verbose        Enable verbose mode"
    echo -e "  -h, --help           Print this message and exit"
    echo -e "\ngen-release:v1.1 <MerhylStudio>"
    exit 1
}

# Function: msg_info
# ----------------------------------------------------------------------
# Print info message
msg_info() {
    local color_Green='\e[0;32m'
    local color_NC='\e[m'
    echo -e "${color_Green}Info: $*${color_NC}" 2>&1
}

# Function: msg_warn
# ----------------------------------------------------------------------
# Print warn message
msg_warn() {
    local color_Yellow='\e[0;33m'
    local color_NC='\e[m'
    echo -e "${color_Yellow}Warning: $*${color_NC}" 2>&1
}

# Function: msg_error
# ----------------------------------------------------------------------
# Print error message
msg_error() {
    local color_bRed='\e[0;31m'
    local color_NC='\e[m'
    echo -e "${color_bRed}Error: $*${color_NC}" 2>&1
}


# Function: exec_command
# ----------------------------------------------------------------------
# Print and execute a command
exec_command() {
    local color_Purple='\e[0;35m'
    local color_NC='\e[m'
    echo -e "${color_Purple}Command:${color_NC} \"$*\"" 2>&1
    bash -c "$*" # > /dev/null 2>&1
}

# Function: bail
# ----------------------------------------------------------------------
# Print error message and return to top of source tree
top_src=$(pwd)
bail() {
    msg_error "$*"
    cd "${top_src}"
}

# Function: die
# ----------------------------------------------------------------------
# Print error message and exit
die() {
    bail "$*"
    echo -e "\nExiting..."
    exit 2
}


# Globals
# ----------------------------------------------------------------------
PKG_VERSION=$1
if [ -z "${PKG_VERSION}" ]; then
    msg_warn "Missing version"
    msg_help
fi

DIR=$( cd "$(dirname "$0")" && pwd )
ROOT_DIR=$( cd "$DIR" && pwd )

# Function: verify_no_local_changes
# ----------------------------------------------------------------------
# Checks that the top commit has been pushed to the remote
verify_no_local_changes() {
    upstream=$1

    # Obtain the top commit SHA which should be the version bump
    # It should not have been tagged yet (the script will do it later)
    local_top_commit_sha=$(git rev-list --max-count=1 HEAD)
    if [ $? -ne 0 ]; then
        bail "Unable to obtain the local top commit id."
        return 1
    fi

    # Check that the top commit has been pushed to remote
    remote_top_commit_sha=$(git rev-list --max-count=1 $upstream)
    if [ $? -ne 0 ]; then
        bail "Unable to obtain top commit from the remote repository."
        return 1
    fi
    if [ x"$remote_top_commit_sha" != x"$local_top_commit_sha" ]; then
        local_top_commit_descr=$(git log --oneline --max-count=1 $local_top_commit_sha)
        bail "The local top commit has not been pushed to the remote." \
             "The local top commit is: \"$local_top_commit_descr\""
        return 1
    fi
    return 0
}

# Function: tag_top_commit
# ----------------------------------------------------------------------
# If a tag exists with the the tar name, ensure it is tagging the top commit
# It may happen if the version has been previously released
tag_top_commit() {
    tag_name=$1

    tagged_commit_sha=$(git rev-list --max-count=1 $tag_name 2>/dev/null)
    if [ $? -eq 0 ]; then
        # Check if the tag is pointing to the top commit
        if [ x"$tagged_commit_sha" != x"$remote_top_commit_sha" ]; then
            remote_top_commit_descr=$(git log --oneline --max-count=1 $remote_top_commit_sha)
            local_tag_commit_descr=$(git log --oneline --max-count=1 $tagged_commit_sha)
            bail "The \"$tag_name\" already exists." \
                 "This tag is not tagging the top commit." \
                 "The top commit is: \"$remote_top_commit_descr\"" \
                 "Tag \"$tag_name\" is tagging some other commit: \"$local_tag_commit_descr\""
            return 1
        else
            msg_warn "Project already tagged with \"$tag_name\"."
        fi
    else
        # Tag the top commit with the tar name
        if [ x"$DRY_RUN" = x ]; then
            git tag -m ${tag_name} ${tag_name}
            if [ $? -ne 0 ]; then
                bail "Unable to tag project with \"$tag_name\"."
                return 1
            else
                msg_info "Project tagged with \"$tag_name\"."
            fi
        else
            msg_info "Skipping the commit tagging in dry-run mode."
        fi
    fi
return 0
}

# Function: push_tag
# ----------------------------------------------------------------------
#
push_tag() {
    tag_name=$1
    remote_name=$2
    msg_info "Pushing tag \"$tag_name\" to remote \"$remote_name\":"
    git push $remote_name $tag_name
    if [ $? -ne 0 ]; then
        bail "Unable to push tag \"$tag_name\" to the remote repository, please fix this manually"
        return 1
    fi
    return 0
}

# Function: create_dist_tarball
# ----------------------------------------------------------------------
# Generate the distribution tarball, or die trying
# Return 0 on success, 1 on fail
create_dist_tarball() {
    tag_name=$1
    # FIXME: Checkout $tag_name if necessary?

    if [ -e Makefile ]; then

  	# make dist
  	msg_info "Running \"make $MAKEFLAGS $MAKE_DIST_CMD\" to create tarballs:"
  	make $MAKEFLAGS $MAKE_DIST_CMD > /dev/null
  	if [ $? -ne 0 ]; then
        bail "\"make $MAKEFLAGS $MAKE_DIST_CMD\" failed."
  	    return 1
  	fi
    elif [ -e Dockerfile ]; then
        # docker build (add --no-cache option if needed)
        exec_command docker build -t $PKG_NAME .
        if [ $? -ne 0 ]; then
            die "Couldn't build docker image"
        fi
        msg_info "Docker image \"$PKG_NAME\" built succesfully"

        # Publish docker image to remote repository
        if [ x$DRY_RUN = x ]; then
            # docker tag
            exec_command docker tag $PKG_NAME $DOCKER_REPO/$PKG_NAME:latest
            if [ $? -ne 0 ]; then
                die "Couldn't tag docker image"
            fi
            exec_command docker tag $PKG_NAME $DOCKER_REPO/$PKG_NAME:$PKG_VERSION
            if [ $? -ne 0 ]; then
                die "Couldn't tag docker image"
            fi

            # docker login
            if [[ "$DOCKER_REPO" =~ "/" ]]; then
                exec_command docker login $DOCKER_REPO
            else
                # if no registry spefified pushing to docker.io
                exec_command docker login
            fi
            if [ $? -ne 0 ]; then
                die "Couldn't connect to docker repository" \
                    "Try to fix this manually"
            fi

            # docker push
            exec_command docker push $DOCKER_REPO/$PKG_NAME:latest
            if [ $? -ne 0 ]; then
                die "Couldn't push docker image"
            fi
            exec_command docker push $DOCKER_REPO/$PKG_NAME:$PKG_VERSION
            if [ $? -ne 0 ]; then
                die "Couldn't push docker image"
            fi
        else
            msg_info "Skipped tagging and pushing docker image in dry-run mode."
        fi
    else
      	# git archive
      	tar_name=$PKG_NAME-$PKG_VERSION
      	tarbz2=$tar_name.tar.bz2
      	tree=HEAD
      	if [ x$DRY_RUN = x ]; then
      	    tree_ish="tags/${tag_name}"
      	fi
      	msg_info "git archive --format=tar $tree --prefix=${tar_name}/ | bzip2 >${tarbz2}"
      	git archive --format=tar $tree --prefix=${tar_name}/ | bzip2 >${tarbz2}
        if [ $? -ne 0 ]; then
      	    bail "Couldn't create tar archive"
      	    return 1
      	fi
      	msg_info "Generated tarball for tags/${tag_name} as ${tarbz2}"
    fi
    return 0
}

# Function: display_contribution_summary
# ----------------------------------------------------------------------
# Prints out percentages of who contributed what this release
#
display_contribution_summary() {
    tag_range=$1
    echo
    msg_info "Contributors for release $tag_range"

    statistics=$(git log --no-merges "$tag_range" | git shortlog --summary -n | cat)

    SAVEIFS=$IFS
    IFS=$(echo -en "\n\b")

    total=0
    for line in ${statistics}; do
      	count=$(echo $line | cut -c1-6)
      	total=$(( $total + $count ))
    done

    for line in ${statistics}; do
      	count=$(echo $line | cut -c1-6)
      	pct=$(( 100 * $count / $total ))
      	echo "$line ($pct%)"
    done
    echo "Total commits: $total"

    IFS=$SAVEIFS
}

# Function: display_change_list
# ----------------------------------------------------------------------
# Print out the shortlog of changes for this release period
#
display_change_list() {
    tag_range=$1
    echo
    msg_info "Full list of changes:"
    git log --no-merges "$tag_range" | git shortlog | cat
}


#
# ----------------------------------------------------------------------
# Script Begins

msg_info "Preparing release $PKG_VERSION"

# Determine what is the current branch and the remote name
current_branch=$(git branch | grep "\*" | sed -e "s/\* //")
remote_name=$(git config --get branch.$current_branch.remote)
remote_branch=$(git config --get branch.$current_branch.merge | cut -d'/' -f3,4)
msg_info "Working off the \"$current_branch\" branch tracking the remote \"$remote_name/$remote_branch\"."

# Check top commit has been pushed
verify_no_local_changes "$remote_name/$remote_branch"
if [ $? -ne 0 ]; then
    die "Local changes. Please sync your repository with the remote one."
fi

# Construct the new tag
tag_name="v${PKG_VERSION}"

# Tag the release
tag_top_commit $tag_name
if [ $? -ne 0 ]; then
    die "Unable to tag top commit"
fi

# Generate the tarball
create_dist_tarball $tag_name
if [ $? -ne 0 ]; then
    die "Failed to create dist tarball."
fi

# Push top commit tag to remote repository
if [ x$DRY_RUN = x ]; then
    push_tag $tag_name $remote_name
    if [ $? -ne 0 ]; then
	      exit 1
    fi
else
    msg_info "Skipped pushing tag \"$tag_name\" to the remote repository \"$remote_name\" in dry-run mode."
fi

#
# ----------------------------------------------------------------------
# Generate the announce e-mail

tag_previous=$(git describe --abbrev=0 HEAD^ 2>/dev/null)
if [ $? -ne 0 ]; then
    msg_warn "Unable to find a previous tag, perhaps a first release on this branch."
fi

# Get a string marking the start and end of our release period
tag_range=$tag_previous..$local_top_commit_sha

display_contribution_summary $tag_range
display_change_list $tag_range
