# Verix - Decentralized Identity System

A blockchain-based identity management system built on Stacks, enabling users to create, manage, and verify their digital identities with Bitcoin-level security.

## Features

- Create and manage digital identities
- Update profile information (name, bio, avatar)
- Add social media links
- Identity verification system
- Time-based verification expiration
- Multiple verification levels

## Smart Contract Functions

### Identity Management

```clarity
(create-identity (name (string-utf8 50)) 
                (bio (string-utf8 280))
                (avatar (optional (string-utf8 256))))
```
Creates a new identity for the caller.

```clarity
(update-identity (name (string-utf8 50))
                (bio (string-utf8 280))
                (avatar (optional (string-utf8 256))))
```
Updates an existing identity.

```clarity
(add-social-link (link (string-utf8 100)))
```
Adds a social media link to the identity.

### Verification System

```clarity
(verify-identity (user principal) 
                (proof (string-utf8 500))
                (expiration uint))
```
Verifies an identity with proof and expiration time.

### Read-Only Functions

```clarity
(get-identity (user principal))
```
Returns the identity information for a given user.

```clarity
(get-verification (user principal) (verifier principal))
```
Returns verification details.

```clarity
(is-verified (user principal) (verifier principal))
```
Checks if a verification is valid and not expired.

## Error Codes

- `404`: Entity not found
- `401`: Unauthorized action
- `410`: Expired verification
- `400`: Invalid input

## Installation

1. Install the [Stacks CLI](https://docs.stacks.co/cli/get-started)
2. Clone this repository
3. Deploy using:
```bash
stx deploy verix.clar --network mainnet
```

## Testing

Run the test suite:
```bash
clarinet test
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

