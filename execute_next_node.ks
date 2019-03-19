// Execute the next manoeuvre node.
//  - estimate burn time based on maximum acceleration
//  - align ship to manoeuvre vector
//  - warp to manoeuvre node
//    - drop out of warp at 10 minutes to realign to manoeuvre vector
//  - perform burn
//  - delete the manoeuvre node

runoncepath("lib/vessel_operations.ks").
ExecuteNextNode().
