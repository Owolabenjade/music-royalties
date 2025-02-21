# Music Royalties Distribution Smart Contract

A decentralized smart contract built on the Stacks blockchain using Clarity for managing music projects, tracking contributions, and automatically distributing royalties to creators and backers.

## Overview

This smart contract enables musicians and creators to:

1. Create music projects with customizable royalty splits
2. Collect funds from backers and supporters
3. Automatically distribute earnings according to predefined royalty percentages

The contract ensures transparency, automation, and trust in the royalty distribution process without requiring intermediaries.

## Features

- **Project Creation**: Establish music projects with custom royalty splits between creator and backers
- **Backer Tracking**: Record contributions from backers with transparent fund allocation
- **Automated Distribution**: Distribute earnings according to predefined percentages
- **Input Validation**: Ensure all operations follow business rules and maintain data integrity

## Smart Contract Functions

### Project Management

#### `create-project`
Creates a new music project with a title and royalty distribution percentages.

```clarity
(define-public (create-project (title (string-ascii 256)) (royalty-split (list 3 uint))))
```

**Parameters:**
- `title`: Name or description of the music project (limited to 256 ASCII characters)
- `royalty-split`: List of three percentage values that must sum to 100:
  - First value: Creator's share percentage
  - Second value: First backer's share percentage
  - Third value: Second backer's share percentage

**Returns:**
- Project ID for the newly created project

**Requirements:**
- Title must not be empty
- Royalty split percentages must sum to 100

#### `pledge`
Allows users to financially back a music project.

```clarity
(define-public (pledge (project-id uint) (amount uint)))
```

**Parameters:**
- `project-id`: ID of the project to back
- `amount`: Amount of STX tokens to pledge

**Returns:**
- Success status (`true` if successful)

**Requirements:**
- Project must exist
- Pledge amount must be greater than zero

#### `distribute-royalties`
Distributes accumulated earnings according to the predefined royalty split.

```clarity
(define-public (distribute-royalties (project-id uint)))
```

**Parameters:**
- `project-id`: ID of the project for which to distribute royalties

**Returns:**
- Success status (`true` if successful)

**Requirements:**
- Project must exist
- Function caller must be the project creator
- Project must have undistributed earnings

## Data Structure

The contract uses the following data maps:

1. **Projects**: Stores all project details including creator, title, royalty split, and earnings
2. **Backers**: Records individual backer contributions
3. **Project-Backers**: Indexes backers by position (supports up to two backers per project)
4. **Backer-Counts**: Tracks the number of backers for each project

## Error Codes

- `u100`: Project not found
- `u102`: Not authorized (caller is not the project creator)
- `u400`: Invalid title (empty string)
- `u401`: Invalid royalty split (percentages do not sum to 100)
- `u402`: Invalid pledge amount (must be greater than zero)
- `u403`: No undistributed earnings

## Usage Example

1. Create a music project:
```clarity
(contract-call? .music-royalties create-project "My Album" (list u70 u20 u10))
```
This creates a project with 70% royalties to the creator, 20% to the first backer, and 10% to the second backer.

2. Back a project:
```clarity
(contract-call? .music-royalties pledge u1 u1000)
```
This pledges 1000 STX tokens to project ID 1.

3. Distribute royalties:
```clarity
(contract-call? .music-royalties distribute-royalties u1)
```
This distributes all accumulated funds according to the royalty split (must be called by project creator).

## Security Considerations

- All user inputs are validated to ensure data integrity
- Royalty splits are verified to sum to 100%
- Only the project creator can distribute royalties
- The contract uses proper error handling and input validation

## Development and Deployment

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet): Clarity development environment
- [Stacks CLI](https://github.com/blockstack/stacks.js): For contract deployment

### Testing
Run the following command to test all contract functions:
```bash
clarinet test
```

### Deployment
Deploy using the Stacks CLI:
```bash
stacks deploy --fee 10000 music-royalties.clar
```

## Project Structure

📦 music-royalties-distribution
 ┣ 📂 contracts
 ┃ ┣ 📜 royalties-distribution.clar  # Main Clarity contract for royalties distribution
 ┃ ┣ 📜 utils.clar                   # Utility functions for common tasks (e.g., token transfer)
 ┃ ┣ 📜 oracle-integration.clar      # Oracle integration for streaming/purchase data (if applicable)
 ┃ ┗ 📜 README.md                    # Documentation on the contract's logic
 ┣ 📂 tests
 ┃ ┣ 📜 royalties-distribution-test.ts  # Unit tests using Clarinet (testing payment calculations, distributions, etc.)
 ┃ ┣ 📜 oracle-test.ts                 # Tests for oracle integrations or data feed simulations
 ┃ ┗ 📜 README.md                     # Testing setup and instructions
 ┣ 📂 scripts
 ┃ ┣ 📜 deploy.ts                     # Deployment script for the contract
 ┃ ┣ 📜 interact.ts                   # Script for interacting with the contract (creating projects, pledging, etc.)
 ┃ ┗ 📜 README.md                     # Instructions for usage of scripts
 ┣ 📂 frontend
 ┃ ┣ 📂 src
 ┃ ┃ ┣ 📜 App.js                      # Main React app (optional for competition or demo purposes)
 ┃ ┃ ┣ 📜 ContractInteractions.js     # Functions for interacting with the contract (creating, viewing, pledging)
 ┃ ┃ ┣ 📜 components/                # UI components (e.g., dashboard, project details, payments)
 ┃ ┗ 📜 README.md                     # Frontend usage and build instructions
 ┣ 📜 README.md                        # Project overview
 ┣ 📜 .clarinet.toml                   # Clarinet configuration file
 ┣ 📜 package.json                     # Dependencies for scripts and frontend
 ┗ 📜 LICENSE                          # Open-source license
