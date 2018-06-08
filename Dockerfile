FROM elixir:1.6.5-alpine

COPY test /opt/tests
WORKDIR /opt/tests

CMD mix test
