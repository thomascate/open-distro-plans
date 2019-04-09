pkg_name=kibana
pkg_version=6.5.4
pkg_origin=open-distro
pkg_license=('Apache-2.0')
pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
pkg_description="Kibana is a browser based analytics and search dashboard for Elasticsearch."
pkg_upstream_url="https://www.elastic.co/products/kibana"
pkg_source="https://artifacts.elastic.co/downloads/${pkg_name}/${pkg_name}-oss-${pkg_version}-linux-x86_64.tar.gz"
pkg_shasum=9730cb8420704716ba91540530f9ea9238d91b9044eaf7e7107aa35fc5fc0684
pkg_deps=(core/node8/8.14.0 core/rsync) # Kibana is only supported if it runs on the version of node that ships with the release
pkg_exports=(
  [port]=server.port
)
pkg_exposes=(port)
pkg_binds_optional=(
  [elasticsearch]="http-port"
)
pkg_bin_dirs=(bin)

do_build () {
  return 0
}

do_install() {
  cp -r "${HAB_CACHE_SRC_PATH}/${pkg_name}-${pkg_version}-linux-x86_64/"* "${pkg_prefix}/"
  # Delete the /config directory created by Kibana installer; habitat lays down
  # /config/kibana.yml
rm -rv "${pkg_prefix}/config/"
}

do_strip() {
  return 0
}

