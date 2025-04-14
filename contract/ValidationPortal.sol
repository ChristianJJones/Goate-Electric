// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./USDMediator.sol";
import "./InstilledInteroperability.sol";

contract ValidationPortal is Ownable {
    USDMediator public usdMediator;
    InstilledInteroperability public interoperability;
    uint256 public constant VALIDATION_REWARD = 0.25 * 10**6; // $0.25 in USDC
    uint256 public constant REQUIRED_VALIDATIONS = 4;

    enum TaskType { Identity, InsuranceClaim, IcerIncident }
    enum ValidationResult { Pending, Yes, No }

    struct ValidationTask {
        TaskType taskType;
        address creator;
        string data;
        uint256 yesCount;
        uint256 noCount;
        bool completed;
        mapping(address => ValidationResult) validations;
    }

    mapping(uint256 => ValidationTask) public tasks;
    uint256 public taskCounter;

    event TaskCreated(uint256 taskId, TaskType taskType, address creator);
    event ValidationSubmitted(uint256 taskId, address validator, ValidationResult result);
    event TaskCompleted(uint256 taskId, bool approved);

    constructor(address _usdMediator, address _interoperability) Ownable(msg.sender) {
        usdMediator = USDMediator(_usdMediator);
        interoperability = InstilledInteroperability(_interoperability);
    }

    function createTask(TaskType taskType, string memory data) external {
        uint256 taskId = taskCounter++;
        ValidationTask storage task = tasks[taskId];
        task.taskType = taskType;
        task.creator = msg.sender;
        task.data = data;
        emit TaskCreated(taskId, taskType, msg.sender);
    }

    function validateTask(uint256 taskId, bool isValid) external {
        ValidationTask storage task = tasks[taskId];
        require(!task.completed, "Task already completed");
        require(task.validations[msg.sender] == ValidationResult.Pending, "Already validated");

        task.validations[msg.sender] = isValid ? ValidationResult.Yes : ValidationResult.No;
        if (isValid) task.yesCount++; else task.noCount++;

        emit ValidationSubmitted(taskId, msg.sender, task.validations[msg.sender]);

        if (task.yesCount >= REQUIRED_VALIDATIONS || task.noCount >= REQUIRED_VALIDATIONS) {
            task.completed = true;
            bool approved = task.yesCount >= REQUIRED_VALIDATIONS;
            if (approved && task.taskType == TaskType.InsuranceClaim) {
                usdMediator.transferUSD(task.creator, /* amount from claim */);
            }
            usdMediator.transferUSD(msg.sender, VALIDATION_REWARD);
            emit TaskCompleted(taskId, approved);
        }
    }
}
