pkg_name=kibana-odfe
KIBANA_VERSION="6.5.4"
KIBANA_PKG_URL="https://artifacts.elastic.co/downloads/kibana/kibana-oss-$KIBANA_VERSION-linux-x86_64.tar.gz"
pkg_version=0.7.0.1
pkg_origin=open-distro
pkg_license=('Apache-2.0')
pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
pkg_description="Kibana is a browser based analytics and search dashboard for Elasticsearch."
# Kibana has the undesirable behaviour of using an unconfigarable temp dir that's relative to its package path.
# This resolves to $pkg_path/optimize and is not writable by anyone other than root
pkg_svc_user="root"
pkg_build_deps=(
  core/coreutils
  core/git
  core/gnupg
  core/maven
  core/node
  core/openjdk11
  core/openssl
  core/zip
)
pkg_deps=(core/node8/8.14.0 core/rsync) # Kibana is only supported if it runs on the version of node that ships with the release
pkg_exports=(
  [port]=kibana_yaml.server.port
)
pkg_exposes=(port)
pkg_binds_optional=(
  [elasticsearch-odfe]="http-port"
)
pkg_bin_dirs=(bin)

do_download() {
  wget -O $HAB_CACHE_SRC_PATH/kibana-oss-$KIBANA_VERSION.tar.gz $KIBANA_PKG_URL
  rm -rf $HAB_CACHE_SRC_PATH/security-kibana-plugin
  git clone https://github.com/opendistro-for-elasticsearch/security-kibana-plugin.git $HAB_CACHE_SRC_PATH/security-kibana-plugin
}

do_unpack() {

  tar -xzf $HAB_CACHE_SRC_PATH/kibana-oss-$KIBANA_VERSION.tar.gz -C $HAB_CACHE_SRC_PATH/
}

do_build() {
  JAVA_HOME="$(pkg_path_for core/openjdk11)"
  export JAVA_HOME

  #Build dep packages and put them in a local maven repo
  #attach
  pushd /hab/cache/src/security-kibana-plugin>/dev/null || exit 1
  git checkout tags/v$pkg_version
  npm install
  COPYPATH="build/kibana/security-kibana-plugin"
  mkdir -p "$COPYPATH"
  cp -a "index.js" "$COPYPATH"
  cp -a "package.json" "$COPYPATH"
  cp -a "lib" "$COPYPATH"
  cp -a "node_modules" "$COPYPATH"
  cp -a "public" "$COPYPATH"
  mvn clean install -Prelease -Dgpg.skip


  #attach
  popd || exit 1

}

do_install() {
  install -vDm644 $HAB_CACHE_SRC_PATH/kibana-$KIBANA_VERSION-linux-x86_64/README.txt "${pkg_prefix}/README.txt"
  install -vDm644 $HAB_CACHE_SRC_PATH/kibana-$KIBANA_VERSION-linux-x86_64/LICENSE.txt "${pkg_prefix}/LICENSE.txt"
  install -vDm644 $HAB_CACHE_SRC_PATH/kibana-$KIBANA_VERSION-linux-x86_64/NOTICE.txt "${pkg_prefix}/NOTICE.txt"

  cp -a $HAB_CACHE_SRC_PATH/kibana-$KIBANA_VERSION-linux-x86_64/* "${pkg_prefix}/"

  mkdir -p $pkg_prefix/plugins/opendistro_security_kibana_plugin
  unzip -q $HAB_CACHE_SRC_PATH/security-kibana-plugin/target/releases/opendistro_security_kibana_plugin-$pkg_version.zip -d $pkg_prefix/plugins/opendistro_security_kibana_plugin
}


#do_install() {
#  cp -r "${HAB_CACHE_SRC_PATH}/${pkg_name}-${pkg_version}-linux-x86_64/"* "${pkg_prefix}/"
#  # Delete the /config directory created by Kibana installer; habitat lays down
#  # /config/kibana.yml
#rm -rv "${pkg_prefix}/config/"
#}

do_strip() {
  return 0
}

