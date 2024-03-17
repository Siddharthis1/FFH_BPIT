import React from "react";
import { ethers } from "ethers";

function RejectLoan({ contract, refugeeAddress }) {
  const handleRejectLoan = async () => {
    try {
      const tx = await contract.rejectLoan(refugeeAddress);
      await tx.wait();
      alert("Loan Rejection Successful!");
    } catch (error) {
      alert("Loan Rejection Failed: " + error.message);
    }
  };

  return (
    <div>
      <h2>Reject Loan</h2>
      <p>Are you sure you want to reject the loan request?</p>
      <button onClick={handleRejectLoan}>Reject Loan</button>
    </div>
  );
}

export default RejectLoan;
