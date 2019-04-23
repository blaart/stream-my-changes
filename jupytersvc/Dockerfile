FROM python:3.7-slim

# Set timezone to UTC by default
RUN ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime

# Install aws-cli
RUN pip install awscli

# add mysql client
RUN apt-get update
RUN apt-get -y install mysql-client

# add yupiter
RUN pip uninstall -y six && pip install six
RUN pip uninstall -y python-dateutil install python-dateutil
RUN pip install jupyter
CMD ["/data/setup.sh"]
