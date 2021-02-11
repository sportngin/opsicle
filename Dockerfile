FROM ruby:slim

RUN apt-get update -q && \
    apt-get install -qy \
    libncurses5-dev libncursesw5-dev gcc libffi-dev make ssh

RUN gem install opsicle

ENTRYPOINT ["opsicle"]
