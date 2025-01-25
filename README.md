# Verix - Decentralized Identity System

A blockchain-based identity management system built on Stacks, enabling users to create, manage, verify, and rate digital identities.

## Features

- Create and manage digital identities
- Update profile information
- Add social media links
- Identity verification system
- User rating mechanism
- Time-based verification expiration

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

### Rating System

```clarity
(rate-identity (user principal)
               (rating uint)
               (comment (optional (string-utf8 280))))
```
Allows users to rate another user's identity.

```clarity
(update-rating (user principal)
               (rating uint)
               (comment (optional (string-utf8 280))))
```
Enables updating a previously submitted rating.

### Read-Only Functions

- `get-identity`: Retrieve user identity information
- `get-verification`: Get verification details
- `is-verified`: Check verification status
- `get-rating`: Retrieve a specific rating
- `get-user-ratings`: Fetch a user's rating information

## Rating Details

- Rating scale: 1-5 stars
- Maximum 5 social links per identity
- Optional comments with ratings

## Error Codes

- `404`: Not found
- `401`: Unauthorized
- `410`: Expired
- `400`: Invalid input
- `409`: Already rated

## Installation & Development

1. Install Stacks CLI
2. Clone repository
3. Deploy: `stx deploy verix.clar --network mainnet`
4. Test: `clarinet test`

## Contributing

1. Fork repository
2. Create feature branch
3. Submit pull request