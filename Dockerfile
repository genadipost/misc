FROM centos/s2i-core-centos7

# Apache HTTP Server image.
#
# Environment:
#  * $HTTPD_LOG_TO_VOLUME (optional) - When set, httpd will log into /var/log/httpd24

ENV HTTPD_VERSION=2.4

ENV SUMMARY="Platform for running Apache httpd $HTTPD_VERSION or building httpd-based application" \
    DESCRIPTION="Apache httpd $HTTPD_VERSION available as docker container, is a powerful, efficient, \
and extensible web server. Apache supports a variety of features, many implemented as compiled modules \
which extend the core functionality. \
These can range from server-side programming language support to authentication schemes. \
Virtual hosting allows one Apache installation to serve many different Web sites."

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="Apache httpd $HTTPD_VERSION" \
      io.openshift.expose-services="8080:http,8443:https" \
      io.openshift.tags="builder,httpd,httpd24" \
      name="centos/httpd-24-centos7" \
      version="$HTTPD_VERSION" \
      release="1" \
      com.redhat.component="httpd24-docker"

EXPOSE 8080
EXPOSE 8443

RUN yum install -y yum-utils && \
    yum install -y centos-release-scl epel-release && \
    INSTALL_PKGS="gettext hostname nss_wrapper bind-utils httpd24 httpd24-mod_ssl" && \
    INSTALL_OPENSHIFT_DOCS_PKGS="git rh-ruby24-ruby rh-ruby24-ruby-devel rh-ruby24-rubygems gcc-c++ redhat-rpm-config make java-1.8.0-openjdk-devel" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS $INSTALL_OPENSHIFT_DOCS_PKGS && \
    rpm -V $INSTALL_PKGS $INSTALL_OPENSHIFT_DOCS_PKGS && \
    yum clean all

ENV HTTPD_CONTAINER_SCRIPTS_PATH=/usr/share/container-scripts/httpd/ \
    HTTPD_APP_ROOT=/opt/app-root \
    HTTPD_CONFIGURATION_PATH=/opt/app-root/etc/httpd.d \
    HTTPD_MAIN_CONF_PATH=/etc/httpd/conf \
    HTTPD_MAIN_CONF_D_PATH=/etc/httpd/conf.d \
    HTTPD_VAR_RUN=/var/run/httpd \
    HTTPD_DATA_PATH=/var/www \
    HTTPD_DATA_ORIG_PATH=/opt/rh/httpd24/root/var/www \
    HTTPD_LOG_PATH=/var/log/httpd24 \
    HTTPD_SCL=httpd24

# When bash is started non-interactively, to run a shell script, for example it
# looks for this variable and source the content of this file. This will enable
# the SCL for all scripts without need to do 'scl enable'.
ENV BASH_ENV=${HTTPD_APP_ROOT}/scl_enable \
    ENV=${HTTPD_APP_ROOT}/scl_enable \
    PROMPT_COMMAND=". ${HTTPD_APP_ROOT}/scl_enable"

COPY ./s2i/bin/ $STI_SCRIPTS_PATH
COPY ./root /

RUN /usr/libexec/httpd-prepare

USER 1001

RUN git clone https://github.com/openshift/openshift-docs &&  \
    cd openshift-docs && \
    scl enable rh-ruby24 'gem install ascii_binder && asciibinder build' && \
    ln -s /opt/app-root/src/openshift-docs/_preview /var/www/html/_preview && \
    rm /etc/httpd/conf.d/welcome.conf && \
    scl enable httpd24 'httpd -k graceful'

CMD ["/usr/bin/run-httpd"]
