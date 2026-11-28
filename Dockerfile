# The demo: IRIS Community with BPL Plus, the demo processes and the demo
# production, in the namespace USER. See "Try it with Docker" in the README.
ARG IMAGE=intersystemsdc/iris-community:latest
FROM $IMAGE

WORKDIR /home/irisowner/bplplus
COPY --chown=irisowner:irisowner . .

RUN iris start IRIS \
 && iris session IRIS < docker/demo.script \
 && iris stop IRIS quietly
