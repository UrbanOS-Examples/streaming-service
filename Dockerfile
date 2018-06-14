FROM elixir:1.6.5-alpine

COPY . /opt/app
WORKDIR /opt/app

RUN mix local.hex --force
RUN mix deps.get

CMD mix test
