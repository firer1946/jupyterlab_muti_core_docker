VERSION="1.0"
docker login
docker build -t multilanguage-jupyter .
docker tag multilanguage-jupyter nicolalandro/multilanguage-jupyter:$VERSION
docker push nicolalandro/multilanguage-jupyter:$VERSION

