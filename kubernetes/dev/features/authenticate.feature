Feature: An authorized client can authenticate as a permitted role

  Scenario: Authenticate as a Pod.
    Given I login to authn-k8s as "inventory-pod"
    Then I can authenticate with authn-k8s as "inventory-pod"

  Scenario: Authenticate as a Deployment.
    Given I login to authn-k8s as "inventory-deployment"
    Then I can authenticate with authn-k8s as "inventory-deployment"

  Scenario: Authenticate as a StatefulSet.
    Given I login to authn-k8s as "inventory-stateful"
    Then I can authenticate with authn-k8s as "inventory-stateful"
