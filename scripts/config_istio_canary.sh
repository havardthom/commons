#!/bin/bash
# uncomment to debug the script
# set -x
# copy the script below into your app code repo (e.g. ./scripts/config_istio_canary.sh) and 'source' it from your pipeline job
#    source ./scripts/config_istio_canary.sh
# alternatively, you can source it from online script:
#    source <(curl -sSL "https://raw.githubusercontent.com/open-toolchain/commons/master/scripts/config_istio_canary.sh")
# ------------------
# source: https://raw.githubusercontent.com/open-toolchain/commons/master/scripts/config_istio_canary.sh

# Configure Istio gateway with virtual service

# Input env variables from pipeline job
echo "PIPELINE_KUBERNETES_CLUSTER_NAME=${PIPELINE_KUBERNETES_CLUSTER_NAME}"
echo "IMAGE_NAME=${IMAGE_NAME}"

if [ -z "${GATEWAY_FILE}" ]; then GATEWAY_FILE=gateway.yaml ; fi
if [ ! -f ${GATEWAY_FILE} ]; then
  cat > ${GATEWAY_FILE} << EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
name: gateway-${IMAGE_NAME}
spec:
selector:
    istio: ingressgateway # use istio default controller
servers:
- port:
    number: 80
    name: http
    protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: destination-rule-${IMAGE_NAME}
spec:
  host: ${IMAGE_NAME}
  subsets:
  - name: stable
    labels:
      version: "stable"
  - name: canary
    labels:
      version: "canary"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
name: virtual-service${IMAGE_NAME}
spec:
hosts:
    - '*'
gateways:
    - gateway-${IMAGE_NAME}
http:
    - route:
        - destination:
            host: ${IMAGE_NAME}
EOF
  sed -e "s/\${IMAGE_NAME}/${IMAGE_NAME}/g" ${GATEWAY_FILE}
fi

kubect apply -f ${GATEWAY_FILE} --namespace ${CLUSTER_NAMESPACE}

kubectl get gateways, destinationrules, virtualservices --namespace ${CLUSTER_NAMESPACE}