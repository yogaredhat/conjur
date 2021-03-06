# Conjur v5 RFC5424 event specification

## Entry structure

Compare for section 6 of RFC 5424 for full explanation of the different fields.

### Priority

Priority header field is a decimal specification of facility and severity of the message.
Conjur messages use facility 4 (traditionally called 'auth'); messages related to user authentication use facility 10 ('authpriv').

Severity depends on the kind of event:
- failed permission checks -- severity 4 ('warn'),
- model and value changes -- severity 5 ('notice'),
- successful permission checks, value fetches -- severity 6 ('info').

### Version

`1` as specified by the RFC.

### Timestamp

Conjur will always emit UTC timestamps with at least millisecond precision.

### Hostname

The full host name of the Conjur server as best can be determined.

### Application name

`conjur`

### Process ID

For messages generated in response to web request, this is a web request GUID. For messages generated for local action, it's the OS process identifier of the originator.

### Message ID

This field is the type of event. Allowed values:
- `authn` for authentication events,
- `check` for permission checks,
- `fetch` for secret value fetches,
- `policy` for policy changes,
- `update` for value changes.

### Structured data

Note: 43868 is the IANA-assigned Private Enterprise Number for Conjur.

#### policy@43868

This SD-ID is used in `policy` messages. All parameters are required.

- `id`: fully-qualified policy id,
- `version`: numeric policy version.

#### subject@43868

This SD-ID specifies the Conjur entity that is the subject of this message. 
All parameters are optional and depend on the specific event.
All identifiers are fully-qualified.

- `annotation`: annotation name,
- `member`: member role id (for membership grant or revocation),
- `owner`: member role id (for ownership),
- `privilege`: subject privilege,
- `resource`: subject resource id,
- `role`: subject role id,
- `version`: when fetching a secret given explicit version, that version.

#### action@43868

This SD-ID specifies the action performed and/or its result. 

- `operation`: optional, one of: `add`, `authenticate`, `remove`, `change`, `update`, `check`, `fetch`,
- `result`: on authentication or permission check, one of: `success`, `failure`.

#### auth@43868

This SD-ID is used on every event log caused by an authenticated user or on
attempted authentication.

- `user`: fully-qualified id of the authenticated user. Note this parameter is
  only present when the user had been successfully authenticated. Events
  related to authentication attempts (whether failed or successful) will instead
  have a `role` parameter on `subject` SD-ID.
- `authenticator`: when authenticating, the name of the authenticator being used.
- `service`: when authenticating, the fully qualified id of the service requested.

### Message

The body of the message should provide English-language summary of the event.

## Message types

### `authn` messages

These messages always have subject@43868/role parameter set to the role on which
authentication is attempted. The facility number is 10.

#### Examples

        <86>1 - - conjur - authn [subject@43868 role="example:user:alice"][auth@43868 authenticator="authn-ldap" service="example:webservice:bacon"][action@43868 operation="authenticate" result="success"] example:user:alice successfully authenticated with authenticator authn-ldap service example:webservice:bacon

### `check` messages

Permission checks (whether failed or successful) emit these messages. Failed
checks carry _warning_ (4) severity, successful _info_ (6).

#### Examples

        <38>1 - - conjur - check [auth@43868 user="cucumber:user:charlie"][subject@43868 role="cucumber:user:bob" resource="cucumber:chunky:bacon" privilege="fry"][action@43868 operation="check" result="success"] cucumber:user:charlie checked if cucumber:user:bob can fry cucumber:chunky:bacon (success)

### `fetch` messages

If a specific version of a secret was requested, `version` parameter will be present in the `subject@43868` field.

#### Examples

        <38>1 - - conjur - fetch [subject@43868 resource="example:variable:dbpass"][auth@43868 user="example:user:alice"][action@43868 operation="fetch"] example:user:alice fetched example:variable:dbpass

### `update` messages

These messages are generated when a secret value is changed. They have
_subject@43868/resource_ pointing to the resource that was modified.

        <37>1 - - conjur - update [subject@43868 resource="example:variable:dbpass"][auth@43868 user="example:user:alice"][action@43868 operation="update"] example:user:alice updated example:variable:dbpass
