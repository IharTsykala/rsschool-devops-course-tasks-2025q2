FROM bitnami/grafana:12.1.0

USER root

COPY provisioning/alerting/ /opt/extra-provisioning/alerting/
COPY provisioning/rules/ /opt/extra-provisioning/rules/
COPY provisioning/datasources/ /opt/extra-provisioning/datasources/
COPY provisioning/grafana.ini /opt/extra-provisioning/grafana.ini

RUN mkdir -p /opt/bitnami/grafana/conf/provisioning/alerting \
    && mkdir -p /opt/bitnami/grafana/conf/provisioning/rules \
    && mkdir -p /opt/bitnami/grafana/conf/provisioning/datasources \
    && ln -sfn /opt/extra-provisioning/alerting/contact-points.yaml /opt/bitnami/grafana/conf/provisioning/alerting/contact-points.yaml \
    && ln -sfn /opt/extra-provisioning/alerting/notification-policies.yaml /opt/bitnami/grafana/conf/provisioning/alerting/notification-policies.yaml \
    && ln -sfn /opt/extra-provisioning/alerting/rule-groups.yaml /opt/bitnami/grafana/conf/provisioning/alerting/rule-groups.yaml \
    && ln -sfn /opt/extra-provisioning/datasources/datasources.yaml /opt/bitnami/grafana/conf/provisioning/datasources/datasources.yaml \
    && ln -sfn /opt/extra-provisioning/grafana.ini /opt/bitnami/grafana/conf/grafana.ini \
    && chown -R 1001:1001 /opt/extra-provisioning

USER 1001
