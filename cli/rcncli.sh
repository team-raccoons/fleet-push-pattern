#!/bin/sh
# Requires gum
# Requires the following environment variables:
# CONF_REPO - path to the git directory with the NGINX configuration files
# FLEET_REPO - path to the git directory with the Fleet gitrepo deployments
# GOOGLE_APPLICATION_CREDENTIALS - path to the service account credentials

DEPLOY_TAG=""
TAG_LIST=""
REGION=""
DRY_RUN=false
SUCCESS=true

check_status () {
  STATUS=$(kubectl -n raccoon-army get gitrepo nginx-web-conf-$REGION -o json | jq ".status")
  DESIRED=$(echo "$STATUS" | jq ".desiredReadyClusters")
  READY=$(echo "$STATUS" | jq ".readyClusters")

  echo "$REGION region ready clusters: $READY/$DESIRED"

  if [[ $DESIRED = $READY ]]
  then
    SUCCESS=true
  else
    SUCCESS=false
    # Added display of non-ready state clusters
    CLUSTER_IDS=$(kubectl -n raccoon-army get clusterGroup $REGION-raccoons -o json | jq ".status.nonReadyClusters")
    echo "Clusters not in ready state: $CLUSTER_IDS"
  fi
}

deploy_tag () {
  cd $FLEET_REPO/fleet/provision || exit 1
  echo $(pwd)

  if $DRY_RUN 
  then
    echo "Dry Run. Region: $REGION, Tag: $DEPLOY_TAG"
    echo $(sed "s/DEPLOY_TAG/$DEPLOY_TAG/" raccoon-gitrepo-nginx-conf-$REGION.yaml)
  else
    gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
    APPLY_CMD=$(sed "s/DEPLOY_TAG/$DEPLOY_TAG/" raccoon-gitrepo-nginx-conf-$REGION.yaml)
    echo "$APPLY_CMD" | kubectl apply -f -
    echo "Update applied"
    for i in {1..6}
    do
      STATUS=$(kubectl -n raccoon-army get gitrepo nginx-web-conf-$REGION -o json | jq ".status")
      LAST_UPDATE=$(echo "$STATUS" | jq '.conditions[] | select(.type == "Ready") | .lastUpdateTime' -r)

      gum spin --title "Updating... $LAST_UPDATE" sleep 5
    done
    kubectl -n raccoon-army get gitrepo nginx-web-conf-$REGION
  fi
}

deploy () {
  REGION="$1"
  deploy_tag
  check_status
  # Intentionally didn't choose to return value of check_status for future refactor
  if $SUCCESS
  then
    return 0
  else
    return 1
  fi
}

deploy_all () {
  deploy "eu" && deploy "us"
}

deploy_tag_menu () {
  MENU_OPT=$(gum choose "Deploy for all regions" "Deploy for US" "Deploy for EU" "Exit")

  case $MENU_OPT in
    "Deploy for all regions")
      deploy_all
      ;;
    "Deploy for US")
      deploy "us"
      ;;
    "Deploy for EU")
      deploy "eu"
      ;;
    "Exit")
      echo "Goodbye!"
      exit 0
      ;;
    *)
      echo "This is weird... exiting..."
      exit 1
      ;;
  esac
}

## Configuration tags ##
get_latest_tag () {
  DEPLOY_TAG=$(git describe --abbrev=0 --tags) && return 0
}

get_reverse_order_tags () {
  TAG_LIST=$(git for-each-ref --format '%(taggerdate),%(refname),%(subject)' refs/tags  --sort=taggerdate | sort -r)
}

new_tag() {
  get_latest_tag
  echo "Current tag: $DEPLOY_TAG"
  echo "New Tag:"
  DEPLOY_TAG=$(gum input --placeholder "Enter git tag")
  echo "$DEPLOY_TAG"
  echo "Tag message:"
  MESSAGE=$(gum input --placeholder "Enter git tag message")
  echo "$MESSAGE"
  
  if $DRY_RUN 
  then
    echo "Dry Run. Tag: $DEPLOY_TAG - Message: $MESSAGE"
  else
    git tag -a "$DEPLOY_TAG" -m "$MESSAGE"
    git push origin "$DEPLOY_TAG"
    echo "Tag $DEPLOY_TAG created and pushed to origin"
  fi
}

select_tag () {
  DEPLOY_TAG=$(echo "$TAG_LIST" | gum table -c "Date,Tag Ref,Tag Message" -w 25,18,50 | cut -d ',' -f2 | cut -d "/" -f3)
}

previous_tag () {
  DEPLOY_TAG=$(echo "$TAG_LIST" | head -2 | tail -1 | cut -d "," -f2 | cut -d "/" -f3)
}

deploy_conf () {
  new_tag
  deploy_tag_menu
}

revert_conf () {
  get_reverse_order_tags
  previous_tag
  deploy_tag_menu
}

deploy_old_conf () {
  get_reverse_order_tags
  select_tag
  deploy_tag_menu
}

## Menu and validation ##

main_menu () {

  MENU_OPT=$(gum choose "Deploy currently committed config" "Revert config" "Deploy old config" "Exit")

  case $MENU_OPT in
    "Deploy currently committed config")
      deploy_conf
      ;;
    "Revert config")
      revert_conf
      ;;
    "Deploy old config")
      deploy_old_conf
      ;;
    "Exit")
      echo "Goodbye!"
      exit 0
      ;;
    *)
      echo "This is weird... exiting..."
      exit 1
      ;;
  esac
}

validate_env () {
  if [[ $CONF_REPO && $FLEET_REPO ]]
  then
    cd $CONF_REPO || exit 1
    echo $(pwd)
    main_menu
  else
    echo "Set CONF_REPO and FLEET_REPO environment variables."
    exit 1
  fi
}

validate_env