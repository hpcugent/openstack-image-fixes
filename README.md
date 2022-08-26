# openstack-image-fixes
OpenStack TripleO Image fixes

How to apply fixes and monitoring scripts to RHOSP 16:

1. Clone this repository by:
git clone https://github.com/hpcugent/openstack-image-fixes /home/stack/fixes

2. If not created yet please create application credential for endpoints checks and functional tests:

copy collectd/configrc-example into colectd/configrc and change following values accordingly:
  OS_APPLICATION_CREDENTIAL_ID
  OS_APPLICATION_CREDENTIAL_SECRET
  OS_PROJECT_ID

3. Edit rest of the configrc values, HEAT_JSON variable described in next step:
  KEYSTONE_ENDPOINT
  HOSTNAME_TO_RUN
  HEAT_ENDPOINT

4. For collectd functional tests alter collectd/heat-template.yaml and change following default parameters:

  vm_flavour:
    default: CPUv1.tiny
  vm_image:
    default: CentOS-8
  user_network:
    default: demo_vm
  nfs_network:
    default: demo_nfs
  floating_ip_id:
    default: dbf39835-41d9-4201-a7bc-b34b7ef32ee6
  floating_ip:
    default: 172.18.245.134

Run "openstack -vvvvv stack create --dry-run --timeout 30 --enable-rollback  -t heat-template.yaml TESTSTACK --fit" and change value of HEAT_JSON variable in collectd/configrc file.
Within openstack client output look for dry-run request "REQ:" and "preview" within URI. Copy JSON after "-d" parameter.
Make sure stack can be built, you can run the command without "--dry-run" parameter.

5. for rsyslog kafka logging over director copy config example and change "<director_fqdn>" and "<cloud_url>"

  cp rsyslog/openstack-logs-to-kafka-over-director.conf.example rsyslog/openstack-logs-to-kafka-over-director.conf

  edit rsyslog/openstack-logs-to-kafka-over-director.conf:
    for swirlix replace <direcor_fqdn> with director00.ctlplane.swirlix.over and <cloud_url> with cloudt1.private.ugent.be
    for munna replace <direcor_fqdn> with director10.ctlplane.munna.over and <cloud_url> with cloud.vscentrum.be

6. Redeploy RHOSP 16

7. Verify that you can see new metrics in prometheus (STF), look for "collectd_endpoints_commands_total" and "collectd_heat_commands_total":

Value different than 0 means there is an issue with endpoint/functional tests
