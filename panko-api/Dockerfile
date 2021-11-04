FROM satellite.ugent.be:5000/hpc-ugent-testing-tier1_osp16-osp16_containers-panko-api:16.1
USER "root"
# Copy required files and patch package
COPY panko_api_controllers_v2_events.py.xdmod.patch /tmp/
COPY panko_storage_impl_sqlalchemy.py.xdmod.patch /tmp/
COPY patch-2.7.6-11.el8.x86_64.rpm /tmp/
# Patch python files for xdmod
RUN rpm -Uvh /tmp/patch-2.7.6-11.el8.x86_64.rpm
RUN patch /usr/lib/python3.6/site-packages/panko/api/controllers/v2/events.py < /tmp/panko_api_controllers_v2_events.py.xdmod.patch
RUN patch /usr/lib/python3.6/site-packages/panko/storage/impl_sqlalchemy.py < /tmp/panko_storage_impl_sqlalchemy.py.xdmod.patch

