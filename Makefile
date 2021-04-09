include make.env

build:
	COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1  docker-compose -f ${DOCKER_COMPOSE_FILE} build --pull --force-rm --parallel --progress=plain
	if [ -x "$$(command -v notify-send)" ]; then																  \
		notify-send "${DOCKER_STACK_NAME} images build completed";									\
	fi

config:
	docker-compose -f ${DOCKER_COMPOSE_FILE} config

pull:
	docker-compose -f ${DOCKER_COMPOSE_FILE} pull
	if [ -x "$$(command -v notify-send)" ]; then																\
		notify-send "${DOCKER_STACK_NAME} stack images pulled from registry";	 		\
	fi

push:
	docker-compose -f ${DOCKER_COMPOSE_FILE} push
	if [ -x "$$(command -v notify-send)" ]; then																\
		notify-send "${DOCKER_STACK_NAME} stack images pushed to registry";	  		\
	fi

test:
	./test.sh
	if [ -x "$$(command -v notify-send)" ]; then																\
		notify-send "${DOCKER_STACK_NAME} images test completed";									\
	fi

clean:
	./clean.sh
