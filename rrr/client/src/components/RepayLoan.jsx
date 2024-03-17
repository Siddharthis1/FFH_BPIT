import React, { useState } from "react";
import { ethers } from "ethers";

function RepayLoan({ contract }) {
  const [repaymentAmount, setRepaymentAmount] = useState("");

  const handleRepayLoan = async () => {
    try {
      const amount = ethers.utils.parseEther(repaymentAmount);
      const tx = await contract.repayLoan(amount);
      await tx.wait();
      alert("Loan Repayment Successful!");
    } catch (error) {
      alert("Loan Repayment Failed: " + error.message);
    }
  };

  return (
    <div className="repay-loan-container">
      <h2>Repay Loan</h2>
      <form
        onSubmit={(e) => {
          e.preventDefault();
          handleRepayLoan();
        }}
      >
        <label>
          Repayment Amount (ETH):
          <input
            type="text"
            value={repaymentAmount}
            onChange={(e) => setRepaymentAmount(e.target.value)}
          />
        </label>
        <br />
        <br />
        <button type="submit">Repay Loan</button>
      </form>
    </div>
  );
}

export default RepayLoan;
