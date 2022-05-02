JUPYTER_CONTAINER = $(shell docker container ls --filter name=jupyter-dev -q)
build:
	docker image prune --force --filter='label=jupyter-dev' && \
	docker build ./ --file jupyter-dev.Dockerfile -t jupyter-dev
run:
	docker run -d --name jupyter-dev -p 8888:8888 -v $(PWD)/src:/workdir/src jupyter-dev
jupyter-dev:
	make build && \
	make run || \
	open http://localhost:8888/lab
remove:
	docker container rm -f $(JUPYTER_CONTAINER)