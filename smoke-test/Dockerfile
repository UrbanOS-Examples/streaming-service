FROM elixir:1.6.5

COPY . /opt/app
WORKDIR /opt/app

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix compile

CMD mix test --trace