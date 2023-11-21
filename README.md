# Lagrange Contracts

## Lagrange Payment

1. User calls `lockRevenue(taskId, hardwareId, numHours)`
   1. Make sure the User approves spending token first
2. The Auction Engine will assign the task to a Computing Provider (CP), calling `assignTask(taskId, cpAddress, collateral)`
3. The CP will lock the collateral in the contract, calling `lockCollateral(taskId)`
   1. Make sure the CP approves spending token first
   2. The task time will start (`block.timestamp + duration`)
4. Either party can call `terminateTask(taskId)`
   1. If the User terminates the task, the CP will be paid for time completed
   2. If the CP terminates the task, the User will be returned the revenue and the CP will have its collateral slashed
5. The Monitoring System will report the task as completed after the taskDeadline, giving the User 3 days to submit a refund Claim
   1. Any submitted claim will go through a verification process
6. After the 3 days (assuming no claim was made), the CP can call `collectRevenue(taskId)` to collect the revenue + collateral
