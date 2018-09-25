@logged-in
Feature: Host Factory name support

  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !policy
      id: database
      body:
        - !layer users
        - !host-factory
          id: users
          layers: [ !layer users ]
    """

  Scenario: The host factory creates a host with dashes
    the list of layers and tokens. 
    
    Given a host factory token for "database/users"
    And I authorize the request with the host factory token
    When I successfully POST "/host_factories/hosts?id=brand-new-host"
    Then the JSON should be:
    """
    {
      "annotations" : [],
      "id": "cucumber:host:brand-new-host",
      "owner": "cucumber:host_factory:database/users",
      "api_key": "@response_api_key@",
      "permissions": [],
      "restricted_to": []
    }
    """

  Scenario: The host factory creates a host with dashes
    the list of layers and tokens. 
    
    Given a host factory token for "database/users"
    And I authorize the request with the host factory token
    When I successfully POST "/host_factories/hosts?id=brand_new_host"
    Then the JSON should be:
    """
    {
      "annotations" : [],
      "id": "cucumber:host:brand_new_host",
      "owner": "cucumber:host_factory:database/users",
      "api_key": "@response_api_key@",
      "permissions": [],
      "restricted_to": []
    }
    """
