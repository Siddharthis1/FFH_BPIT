// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract FFH {
    address payable public government;
    uint256 public finePerDay; // Fine amount per day for late repayment
    uint256 public defaulterThreshold; // Fine threshold for being marked as a defaulter

    enum LoanRepaymentScheme { Monthly, Quarterly }

    struct Loan {
        uint256 amount;
        uint256 repaymentAmount;
        uint256 repaymentDate;
        bool repaid;
    }

    struct Refugee {
        address accountAddress;
        string name;
        string phoneNumber;
        string nationality;
        string currentAddress;
        uint256 unhrcID;
        uint256 loanInstallmentAmount;
        uint256 lastRepaymentDate;
        LoanRepaymentScheme repaymentScheme;
        Loan loan;
    }

    struct VerifiedLoan {
        address refugeeAddress;
        uint256 loanAmount;
        LoanRepaymentScheme repaymentScheme;
    }

    Refugee[] public verifiedRefugees;
    Refugee[] public nonVerifiedRefugees;
    mapping(address => uint256) public refugeeBalances;
    mapping(address => bool) public defaulters;
    VerifiedLoan[] public verifiedLoans;

    event RefugeeRegistered(address indexed refugee);
    event RefugeeVerified(address indexed refugee, uint256 amountReceived);
    event RefugeeRejected(address indexed refugee);
    event LoanTaken(address indexed refugee, uint256 amount, LoanRepaymentScheme repaymentScheme);
    event LoanRepaid(address indexed refugee, uint256 amount);
    event LoanDefaulted(address indexed refugee, uint256 fineAmount);
    event ReminderSent(address indexed refugee, string message);
    event LoanRejected(address indexed refugee, uint256 amount);
    event LoanVerified(address indexed refugee, uint256 loanAmount, LoanRepaymentScheme repaymentScheme);

    modifier onlyGovernment() {
        require(msg.sender == government, "Only government can call this function");
        _;
    }

    constructor() {
        government = payable(msg.sender);
        finePerDay = 0.001 ether; // Set default fine amount per day
        defaulterThreshold = 0.1 ether; // Set default threshold for being marked as a defaulter
    }

    function registerAsRefugee(string memory _name, string memory _phoneNumber, string memory _nationality, string memory _currentAddress, uint256 _unhrcID) external payable {
        nonVerifiedRefugees.push(Refugee(msg.sender, _name, _phoneNumber, _nationality, _currentAddress, _unhrcID, 0, 0, LoanRepaymentScheme.Monthly, Loan(0, 0, 0, false)));
        refugeeBalances[msg.sender] += msg.value; // Add deposited amount to refugee balance
        emit RefugeeRegistered(msg.sender);
    }

    function verifyRefugee(address _refugeeAddress) external payable onlyGovernment {
        require(isNonVerifiedRefugee(_refugeeAddress), "Refugee not found or already verified");

        uint256 amountToTransfer = 0.05 ether; // Amount to be transferred to the verified refugee
        require(address(this).balance >= amountToTransfer, "Insufficient contract balance");

        Refugee memory refugeeToVerify;
        for (uint256 i = 0; i < nonVerifiedRefugees.length; i++) {
            if (nonVerifiedRefugees[i].accountAddress == _refugeeAddress) {
                refugeeToVerify = nonVerifiedRefugees[i];
                break;
            }
        }

        verifiedRefugees.push(refugeeToVerify);
        removeNonVerifiedRefugee(_refugeeAddress);
        refugeeBalances[_refugeeAddress] += amountToTransfer; // Transfer 0.05 ether to verified refugee
        payable(_refugeeAddress).transfer(amountToTransfer); // Transfer funds to the verified refugee

        emit RefugeeVerified(_refugeeAddress, amountToTransfer);
    }

    function rejectRefugee(address _refugeeAddress) external onlyGovernment {
        require(isNonVerifiedRefugee(_refugeeAddress), "Refugee not found or already verified");

        removeNonVerifiedRefugee(_refugeeAddress);

        emit RefugeeRejected(_refugeeAddress);
    }

    function takeLoan(uint256 _amount, LoanRepaymentScheme _repaymentScheme) external {
        require(isVerifiedRefugee(msg.sender), "Only verified refugees can take loans");
        require(_amount > 0, "Loan amount must be greater than 0");

        nonVerifiedRefugees.push(Refugee(msg.sender, "", "", "", "", 0, 0, 0, LoanRepaymentScheme.Monthly, Loan(_amount, 0, 0, false)));
        emit LoanTaken(msg.sender, _amount, _repaymentScheme);
    }

    function approveLoan(address _refugeeAddress) external payable onlyGovernment {
        require(isNonVerifiedLoan(_refugeeAddress), "Loan request not found or already approved");

        Refugee memory loanRefugee = getNonVerifiedLoan(_refugeeAddress);
        VerifiedLoan memory newVerifiedLoan = VerifiedLoan(_refugeeAddress, loanRefugee.loan.amount, loanRefugee.repaymentScheme);

        verifiedLoans.push(newVerifiedLoan);
        removeNonVerifiedLoan(_refugeeAddress);

        refugeeBalances[_refugeeAddress] += loanRefugee.loan.amount; // Transfer loan amount to the refugee
        payable(_refugeeAddress).transfer(loanRefugee.loan.amount); // Transfer funds to the verified refugee

        emit RefugeeVerified(_refugeeAddress, loanRefugee.loan.amount);
        emit LoanVerified(_refugeeAddress, loanRefugee.loan.amount, loanRefugee.repaymentScheme);
    }

    function rejectLoan(address _refugeeAddress) external onlyGovernment {
        require(isNonVerifiedLoan(_refugeeAddress), "Loan request not found or already approved");

        removeNonVerifiedLoan(_refugeeAddress);

        emit LoanRejected(_refugeeAddress, getNonVerifiedLoanAmount(_refugeeAddress));
    }

    function repayLoan(uint256 _amount) external {
    require(isVerifiedRefugee(msg.sender), "Only verified refugees can repay loans");
    require(_amount > 0, "Repayment amount must be greater than 0");

    Refugee storage refugee = getRefugee(msg.sender);
    require(refugee.loan.amount > 0, "Refugee does not have an active loan");
    require(refugeeBalances[msg.sender] >= _amount, "Insufficient balance for repayment");

    uint256 fineAmount = calculateFine(refugee);
    uint256 totalRepaymentAmount = refugee.loan.repaymentAmount + fineAmount;

    require(_amount >= totalRepaymentAmount, "Insufficient repayment amount");

    // Transfer repayment amount to the government account
    government.transfer(_amount);

    refugee.loan.amount -= refugee.loan.repaymentAmount; // Reduce loan amount by the installment amount
    refugee.loan.repaid = refugee.loan.amount == 0; // Mark loan as fully repaid if the amount is zero
    refugeeBalances[msg.sender] -= _amount; // Deduct repayment amount from refugee balance

    emit LoanRepaid(msg.sender, _amount);

    if (fineAmount > 0) {
        if (fineAmount >= defaulterThreshold) {
            defaulters[msg.sender] = true; // Mark the refugee as a defaulter if fine exceeds the threshold
            emit LoanDefaulted(msg.sender, fineAmount);
        }
    }

    if (refugee.loan.repaid) {
        // Additional logic can be added here for handling fully repaid loans
    }
}

    function remindForRepayment() external {
        require(isVerifiedRefugee(msg.sender), "Only verified refugees can receive reminders");

        Refugee storage refugee = getRefugee(msg.sender);
        require(refugee.loan.amount > 0, "Refugee does not have an active loan");

        uint256 daysSinceLastRepayment = (block.timestamp - refugee.lastRepaymentDate) / 1 days;
        require(daysSinceLastRepayment >= 25, "Reminder can be sent after 25 days of last repayment date");

        string memory message = "Your loan repayment is due soon. Please make the payment to avoid fines.";
        emit ReminderSent(msg.sender, message);
    }

    function calculateFine(Refugee storage _refugee) private view returns (uint256) {
        uint256 daysSinceLastRepayment = (block.timestamp - _refugee.lastRepaymentDate) / 1 days;
        uint256 fineAmount = finePerDay * daysSinceLastRepayment;
        return fineAmount;
    }

    function checkActualBalance() external view returns (uint256) {
        return msg.sender.balance; // Return actual balance of the refugee's address
    }

    function checkBalance() external view returns (uint256) {
        return refugeeBalances[msg.sender]; // Return balance tracked in the contract
    }

    function getAllVerifiedRefugees() external view onlyGovernment returns (Refugee[] memory) {
        return verifiedRefugees;
    }

    function getAllNonVerifiedRefugees() external view onlyGovernment returns (Refugee[] memory) {
        return nonVerifiedRefugees;
    }

    function getAllNonVerifiedLoans() external view onlyGovernment returns (Refugee[] memory) {
        return nonVerifiedRefugees;
    }

    function getAllVerifiedLoans() external view onlyGovernment returns (VerifiedLoan[] memory) {
        return verifiedLoans;
    }

    function isVerifiedRefugee(address _refugeeAddress) public view returns (bool) {
        for (uint256 i = 0; i < verifiedRefugees.length; i++) {
            if (verifiedRefugees[i].accountAddress == _refugeeAddress) {
                return true;
            }
        }
        return false;
    }

    function isNonVerifiedRefugee(address _refugeeAddress) public view returns (bool) {
        for (uint256 i = 0; i < nonVerifiedRefugees.length; i++) {
            if (nonVerifiedRefugees[i].accountAddress == _refugeeAddress) {
                return true;
            }
        }
        return false;
    }

    function isNonVerifiedLoan(address _refugeeAddress) public view returns (bool) {
        for (uint256 i = 0; i < nonVerifiedRefugees.length; i++) {
            if (nonVerifiedRefugees[i].accountAddress == _refugeeAddress && nonVerifiedRefugees[i].loan.amount > 0) {
                return true;
            }
        }
        return false;
    }

    function getNonVerifiedLoan(address _refugeeAddress) public view returns (Refugee memory) {
        for (uint256 i = 0; i < nonVerifiedRefugees.length; i++) {
            if (nonVerifiedRefugees[i].accountAddress == _refugeeAddress && nonVerifiedRefugees[i].loan.amount > 0) {
                return nonVerifiedRefugees[i];
            }
        }
        revert("Loan request not found");
    }

    function getNonVerifiedLoanAmount(address _refugeeAddress) public view returns (uint256) {
        for (uint256 i = 0; i < nonVerifiedRefugees.length; i++) {
            if (nonVerifiedRefugees[i].accountAddress == _refugeeAddress && nonVerifiedRefugees[i].loan.amount > 0) {
                return nonVerifiedRefugees[i].loan.amount;
            }
        }
        revert("Loan request not found");
    }

    function removeNonVerifiedRefugee(address _refugeeAddress) private {
        for (uint256 i = 0; i < nonVerifiedRefugees.length; i++) {
            if (nonVerifiedRefugees[i].accountAddress == _refugeeAddress) {
                nonVerifiedRefugees[i] = nonVerifiedRefugees[nonVerifiedRefugees.length - 1];
                nonVerifiedRefugees.pop();
                break;
            }
        }
    }

    function removeNonVerifiedLoan(address _refugeeAddress) private {
        for (uint256 i = 0; i < nonVerifiedRefugees.length; i++) {
            if (nonVerifiedRefugees[i].accountAddress == _refugeeAddress && nonVerifiedRefugees[i].loan.amount > 0) {
                nonVerifiedRefugees[i] = nonVerifiedRefugees[nonVerifiedRefugees.length - 1];
                nonVerifiedRefugees.pop();
                break;
            }
        }
    }

    function getRefugee(address _refugeeAddress) private view returns (Refugee storage) {
        for (uint256 i = 0; i < verifiedRefugees.length; i++) {
            if (verifiedRefugees[i].accountAddress == _refugeeAddress) {
                return verifiedRefugees[i];
            }
        }
        revert("Refugee not found");
    }

    // Fallback function to receive ether
    receive() external payable {}
}
