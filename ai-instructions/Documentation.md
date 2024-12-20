Follow up the instructions below and create the full documentation for all solidity smart contracts provided. Return me only the needed documentation text. Check on the provided code when necessary and pay attention on its comments for more relevant details.

The structure of the documentation must follow the rules:
- Follow the instruction of the markdown format provided on this document
- Ignore all private or internal constants, variables and functions, focus on external and public ONLY
- Do NEVER document things that are not on the smart contract
- Provide a clean response and easy to understand

# Default Markdown Structure
## **Events**
- **EventName**: Event description
    - `variableName`: `uint256`

## Structs

- **StructName**: Struct description
    - `lastTimeStamp`: `uint256`

## Constants

- **CONSTANT_NAME**: `type accessModifier` Description

## State Variables

- **stateVariableName**: `type accessModifier` Description

## Modifiers

- `modifierName(arguments if any)`: Description

## Functions

### Constructor

- Description: Initializes contract parameters
- Arguments:
    - `arg1`: `type` Description
    - `arg2`: `type` Description
    - ...

### FunctionName

- Description: What the function does
- Arguments:
    - `arg1`: `type` Description
    - `arg2`: `type` Description
    - ...
- Modifiers:
    - `modifierName`: Description

When a function returns a value, specify the return type in the function description, and if it returns an ABI-encoded data `bytes`, provide the structure of the encoded data.

### **FunctionName**

- Description: What the function does
- Arguments:
    - `arg1`: `type` Description
    - `arg2`: `type` Description
    - `arg3`: `bytes` Description (example bytes argument)
        - Encoded as:
            - `field1`: `type1` Description
            - `field2`: `type2` Description
            - ...
    - ...
- Returns:
    - `return1`: `type` Description
    - `return2`: `bytes` Description (example bytes return)
        - Encoded as:
            - `field1`: `type1` Description
            - `field2`: `type2` Description
            - ...
