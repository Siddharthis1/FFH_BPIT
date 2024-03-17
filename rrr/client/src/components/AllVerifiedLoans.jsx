import React, { useState, useEffect } from "react";
import { ethers } from "ethers";


function AllVerifiedLoans({ contract }) {
  const [verifiedLoans, setVerifiedLoans] = useState([]);

  useEffect(() => {
    const fetchVerifiedLoans = async () => {
      try {
        const loans = await contract.getAllVerifiedLoans();
        setVerifiedLoans(loans);
      } catch (error) {
        console.error("Error fetching verified loans:", error);
      }
    };

    fetchVerifiedLoans();
  }, [contract]);

  return (
    <div className="all-verified-loans-container">
      <h2>All Verified Loans</h2>
      {verifiedLoans.length > 0 ? (
        <table className="loans-table">
          <thead>
            <tr>
              <th>Refugee Address</th>
              <th>Loan Amount</th>
              <th>Repayment Scheme</th>
            </tr>
          </thead>
          <tbody>
            {verifiedLoans.map((loan, index) => (
              <tr key={index}>
                <td>{loan.refugeeAddress}</td>
                <td>{ethers.utils.formatEther(loan.loanAmount)} ETH</td>
                <td>{loan.repaymentScheme}</td>
              </tr>
            ))}
          </tbody>
        </table>
      ) : (
        <p className="no-data">No verified loans found.</p>
      )}
    </div>
  );
}

export default AllVerifiedLoans;
