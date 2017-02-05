Trellifier
==========

Questions
---------
- why are tests with `.exs` extension?
- how do I know the structure of processes of the system and if it's optimal?

Running
-------
Do this for iex history (without tab completion):

```bash
eval $(gpg -d secrets/secrets.sh.gpg)
rlwrap -a -A iex -S mix phoenix.server
```

To start your Phoenix app:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `npm install`
  * Start Phoenix endpoint with `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

Setup
--------

Install elixir: http://www.phoenixframework.org/docs/installation

```bash
sudo apt install -y erlang-observer erlang-dev
sudo apt-get install erlang-base-hipe
# may need to install erlang-parsetools as well
```

Releasing
---------

```bash
eval $(gpg -d secrets/secrets.sh.gpg)
./deploy.sh


MIX_ENV=prod mix do compile, release
git tag "v$(cat mix.exs | grep -A2 'def project' | grep version | sed -e's/^.\+version: "//' -e's/",//')"

docker build --build-arg="VERSION=$(cat mix.exs | grep -A2 'def project' | grep version | sed -e's/^.\+version: "//' -e's/",//')" -t 663971007925.dkr.ecr.us-west-1.amazonaws.com/trellifier:$(git rev-parse HEAD | awk '{$1 = substr($1, 1, 7)} 1') .
docker tag 663971007925.dkr.ecr.us-west-1.amazonaws.com/trellifier:$(git rev-parse HEAD | awk '{$1 = substr($1, 1, 7)} 1') 663971007925.dkr.ecr.us-west-1.amazonaws.com/trellifier:latest
docker push 663971007925.dkr.ecr.us-west-1.amazonaws.com/trellifier:$(git rev-parse HEAD | awk '{$1 = substr($1, 1, 7)} 1') ; docker push 663971007925.dkr.ecr.us-west-1.amazonaws.com/trellifier:latest

ssh -fN -Llocalhost:2377:localhost:2375 periodic
export DOCKER_HOST='tcp://localhost:2377'
docker pull 663971007925.dkr.ecr.us-west-1.amazonaws.com/trellifier:$(git rev-parse HEAD | awk '{$1 = substr($1, 1, 7)} 1') ; docker push 663971007925.dkr.ecr.us-west-1.amazonaws.com/trellifier:latest
docker rm -f trellifier ; docker run -d -e TRELLO_API_KEY -e TRELLO_API_TOKEN -e TWILIO_ACCOUNT_SID -e TWILIO_AUTH_TOKEN -e TWILIO_FROM_NUMBER -e ALEX_BIRD_CELL --restart=always --name=trellifier -p 0.0.0.0:8888:8888 663971007925.dkr.ecr.us-west-1.amazonaws.com/trellifier:latest
```
