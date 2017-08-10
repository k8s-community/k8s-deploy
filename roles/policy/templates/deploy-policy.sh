#!/bin/bash

function deploy_namespaces {
    if kubectl get namespaces | grep release &> /dev/null; then
        echo "Namespaces already exist"
    else
        echo "Creating namespaces"
        kubectl apply -f {{ k8s_policy_dir }}/namespaces.yaml
    fi

  echo
}

function deploy_admin_cluster_role_binding {
    if kubectl get -l basic.auth/user=admin clusterrolebindings | grep admin &> /dev/null; then
        echo "Admin role already exists"
    else
        echo "Creating admin role and binding"
        kubectl apply -f {{ k8s_policy_dir }}/admin-clusterrolebinding.yaml
    fi

  echo
}

function deploy_reader_cluster_role {
    if kubectl get -l basic.auth/role=cluster-reader clusterrole | grep cluster-reader &> /dev/null; then
        echo "Cluster reader role already exists"
    else
        echo "Creating cluster reader role and binding"
        kubectl apply -f {{ k8s_policy_dir }}/cluster-reader-clusterrole.yaml
        kubectl apply -f {{ k8s_policy_dir }}/cluster-reader-clusterrolebinding.yaml
    fi

  echo
}

function deploy_release_role {
    if kubectl get -l basic.auth/role=release-admin role --namespace=release | grep release-admin &> /dev/null; then
        echo "Release role already exists"
    else
        echo "Creating release role and binding"
        kubectl apply -f {{ k8s_policy_dir }}/release-role.yaml
        kubectl apply -f {{ k8s_policy_dir }}/release-rolebinding.yaml
    fi

  echo
}

function deploy_tls_secrets {
    if kubectl get secrets --namespace=kube-system | grep tls-secret &> /dev/null; then
        echo "tls secret already exists"
    else
        echo "Creating tls secret"
{% if k8s_services_cert | length > 1000 %}
        kubectl apply -f {{ k8s_policy_dir }}/tls_secret.yaml
{% else %}
        echo "
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
data:
  tls.crt: `base64 --wrap=0 {{ ssl_dir }}/{{ ssl_name }}.pem`
  tls.key: `base64 --wrap=0 {{ ssl_dir }}/{{ ssl_name }}-key.pem`
---
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
  namespace: kube-system
data:
  tls.crt: `base64 --wrap=0 {{ ssl_dir }}/{{ ssl_name }}.pem`
  tls.key: `base64 --wrap=0 {{ ssl_dir }}/{{ ssl_name }}-key.pem`
---
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
  namespace: prod
data:
  tls.crt: `base64 --wrap=0 {{ ssl_dir }}/{{ ssl_name }}.pem`
  tls.key: `base64 --wrap=0 {{ ssl_dir }}/{{ ssl_name }}-key.pem`
---
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
  namespace: release
data:
  tls.crt: `base64 --wrap=0 {{ ssl_dir }}/{{ ssl_name }}.pem`
  tls.key: `base64 --wrap=0 {{ ssl_dir }}/{{ ssl_name }}-key.pem`
" | kubectl apply -f -
{% endif %}
    fi

  echo
}


deploy_namespaces
deploy_admin_cluster_role_binding
deploy_reader_cluster_role
deploy_release_role
deploy_tls_secrets
