import React, { useState } from "react";
import { ethers } from "ethers";

function TakeLoan({ contract }) {
  const [loanAmount, setLoanAmount] = useState("");
  const [repaymentScheme, setRepaymentScheme] = useState("Monthly");

  const handleTakeLoan = async () => {
    try {
      const amount = ethers.utils.parseEther(loanAmount);
      const tx = await contract.takeLoan(amount, repaymentScheme);
      await tx.wait();
      alert("Loan Request Successful!");
    } catch (error) {
      alert("Loan Request Failed: " + error.message);
    }
  };

  return (
    <div className="take-loan-container">
      <h2>Take Loan</h2>
      <form
        onSubmit={(e) => {
          e.preventDefault();
          handleTakeLoan();
        }}
      >
        <label>
          Loan Amount (ETH):
          <input
            type="text"
            value={loanAmount}
            onChange={(e) => setLoanAmount(e.target.value)}
          />
        </label>
        <br />
        <label>
          Repayment Scheme:
          <select
            value={repaymentScheme}
            onChange={(e) => setRepaymentScheme(e.target.value)}
          >
            <option value="Monthly">Monthly</option>
            <option value="Quarterly">Quarterly</option>
          </select>
        </label>
        <br />
        <br />
        <button type="submit">Take Loan</button>
      </form>
    </div>
  );
}

export default TakeLoan;
