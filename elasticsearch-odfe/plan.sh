# This is the version that the current ODFE package depends on
ELASTICSEARCH_VERSION="6.5.4"
ELASTICSEARCH_PKG_URL="https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-oss-$ELASTICSEARCH_VERSION.tar.gz"
pkg_version=0.7.0.1
pkg_name="elasticsearch-odfe"
pkg_description="Open Distro for Elasticsearch plugins"
pkg_origin="chef"
vendor_origin="chef"
pkg_maintainer="Chef Software Inc. <support@chef.io>"
pkg_license=("Chef-MLSA")
pkg_upstream_url="https://github.com/opendistro-for-elasticsearch"
pkg_build_deps=(
  core/coreutils
  core/git
  core/maven
  core/openjdk11
  core/openssl
  core/zip
)
pkg_deps=( 
  core/coreutils
  core/curl
  core/glibc
  chef/mlsa
  core/openjdk11
  core/procps-ng
  core/ruby
  core/wget
  core/zlib
)

pkg_bin_dirs=(bin)
pkg_binds_optional=(
  [elasticsearch]="http-port transport-port"
)
pkg_lib_dirs=(lib)
pkg_exports=(
  [http-port]=es_yaml.http.port
  [transport-port]=es_yaml.transport.tcp.port
)
pkg_exposes=(http-port transport-port)

ODFE_DEPENDENCIES=(
  'security-parent'
  'security-ssl'
  'security-advanced-modules'
  )

do_download() {
  wget -O $HAB_CACHE_SRC_PATH/elasticsearch-oss-$ELASTICSEARCH_VERSION.tar.gz $ELASTICSEARCH_PKG_URL
  for component in "${ODFE_DEPENDENCIES[@]}"; do
    rm -rf $HAB_CACHE_SRC_PATH/$component
    git clone https://github.com/opendistro-for-elasticsearch/$component.git $HAB_CACHE_SRC_PATH/$component
  done

  rm -rf $HAB_CACHE_SRC_PATH/security
  git clone https://github.com/opendistro-for-elasticsearch/security.git $HAB_CACHE_SRC_PATH/security
}

do_unpack() {
  tar -xzf $HAB_CACHE_SRC_PATH/elasticsearch-oss-$ELASTICSEARCH_VERSION.tar.gz -C $HAB_CACHE_SRC_PATH/
}

do_build() {
  JAVA_HOME="$(pkg_path_for core/openjdk11)"
  export JAVA_HOME

  #Build dep packages and put them in a local maven repo
  for component in "${ODFE_DEPENDENCIES[@]}"; do
    pushd $HAB_CACHE_SRC_PATH/$component >/dev/null || exit 1
    git checkout tags/v$pkg_version
    mvn compile -Dmaven.test.skip=true
    mvn package -Dmaven.test.skip=true
    mvn install -Dmaven.test.skip=true
    popd || exit 1
  done

  #Build the opendistro_security plugin itself
  pushd $HAB_CACHE_SRC_PATH/security >/dev/null || exit 1
  git checkout tags/v$pkg_version
  mvn compile -Dmaven.test.skip=true -P advanced
  mvn package -Dmaven.test.skip=true -P advanced
  mvn install -Dmaven.test.skip=true -P advanced
  popd || exit 1
}

do_install() {
  install -vDm644 $HAB_CACHE_SRC_PATH/kibana-$KIBANA_VERSION/README.textile "${pkg_prefix}/README.textile"
  install -vDm644 $HAB_CACHE_SRC_PATH/kibana-$KIBANA_VERSION/LICENSE.txt "${pkg_prefix}/LICENSE.txt"
  install -vDm644 $HAB_CACHE_SRC_PATH/kibana-$KIBANA_VERSION/NOTICE.txt "${pkg_prefix}/NOTICE.txt"

  cp -a $HAB_CACHE_SRC_PATH/elasticsearch-$ELASTICSEARCH_VERSION/* "${pkg_prefix}/"

  # Delete unused binaries to save space
  rm "${pkg_prefix}/bin/"*.bat "${pkg_prefix}/bin/"*.exe

  mkdir -p $pkg_prefix/plugins/opendistro_security
  unzip $HAB_CACHE_SRC_PATH/security/target/releases/opendistro_security-$pkg_version.zip -d $pkg_prefix/plugins/opendistro_security
}
