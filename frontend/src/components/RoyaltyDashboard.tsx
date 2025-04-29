import React, { useState, useEffect } from 'react';
import { Card, Table, InputNumber, Button, message, Statistic, Row, Col } from 'antd';
import { useWallet } from '@aptos-labs/wallet-adapter-react';
import { AptosClient } from '@aptos-labs/ts-sdk';
import { NODE_URL } from '../config/constants';

interface RoyaltyPayment {
  amount: number;
  timestamp: number;
}

interface PatentDetails {
  patentId: string;
  totalSupply: number;
  royaltyRate: number;
  totalDistributed: number;
  paymentHistory: RoyaltyPayment[];
}

const RoyaltyDashboard: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [patentDetails, setPatentDetails] = useState<PatentDetails | null>(null);
  const [distributionAmount, setDistributionAmount] = useState<number>(0);
  const { account, signAndSubmitTransaction } = useWallet();
  const aptosClient = new AptosClient(NODE_URL);

  useEffect(() => {
    if (account) {
      fetchPatentDetails();
    }
  }, [account]);

  const fetchPatentDetails = async () => {
    try {
      const resource = await aptosClient.getAccountResource(
        account!.address,
        `${account!.address}::royalty_distributor::RoyaltyPayment`
      );

      const [patentId, totalSupply, royaltyRate] = await aptosClient.view({
        function: `${account!.address}::patent_token::get_patent_details`,
        type_arguments: [],
        arguments: [account!.address],
      });

      const [totalDistributed, lastTime, paymentHistory] = await aptosClient.view({
        function: `${account!.address}::royalty_distributor::get_payment_history`,
        type_arguments: [],
        arguments: [account!.address],
      });

      setPatentDetails({
        patentId: patentId as string,
        totalSupply: Number(totalSupply),
        royaltyRate: Number(royaltyRate),
        totalDistributed: Number(totalDistributed),
        paymentHistory: (paymentHistory as number[]).map((amount, index) => ({
          amount,
          timestamp: Number(lastTime) - (paymentHistory.length - index - 1) * 86400, // Approximate timestamps
        })),
      });
    } catch (error) {
      console.error('Error fetching patent details:', error);
      message.error('Failed to fetch patent details');
    }
  };

  const handleDistribute = async () => {
    if (!account || !patentDetails || distributionAmount <= 0) return;

    setLoading(true);
    try {
      const payload = {
        type: "entry_function_payload",
        function: `${account.address}::royalty_distributor::distribute_royalties`,
        type_arguments: [],
        arguments: [
          patentDetails.patentId,
          distributionAmount.toString(),
        ],
      };

      const response = await signAndSubmitTransaction(payload);
      await aptosClient.waitForTransaction(response.hash);

      message.success('Royalties distributed successfully!');
      setDistributionAmount(0);
      fetchPatentDetails();
    } catch (error) {
      console.error('Error distributing royalties:', error);
      message.error('Failed to distribute royalties');
    } finally {
      setLoading(false);
    }
  };

  const columns = [
    {
      title: 'Amount',
      dataIndex: 'amount',
      key: 'amount',
      render: (amount: number) => `${amount} APT`,
    },
    {
      title: 'Date',
      dataIndex: 'timestamp',
      key: 'timestamp',
      render: (timestamp: number) => new Date(timestamp * 1000).toLocaleDateString(),
    },
  ];

  return (
    <div style={{ maxWidth: 800, margin: '0 auto' }}>
      <Row gutter={[16, 16]}>
        <Col span={8}>
          <Card>
            <Statistic
              title="Total Distributed"
              value={patentDetails?.totalDistributed || 0}
              suffix="APT"
            />
          </Card>
        </Col>
        <Col span={8}>
          <Card>
            <Statistic
              title="Royalty Rate"
              value={patentDetails?.royaltyRate || 0}
              suffix="%"
            />
          </Card>
        </Col>
        <Col span={8}>
          <Card>
            <Statistic
              title="Total Supply"
              value={patentDetails?.totalSupply || 0}
            />
          </Card>
        </Col>
      </Row>

      <Card title="Distribute Royalties" style={{ marginTop: 16 }}>
        <InputNumber
          style={{ width: '100%', marginBottom: 16 }}
          placeholder="Enter amount in APT"
          value={distributionAmount}
          onChange={(value) => setDistributionAmount(value || 0)}
          min={0}
        />
        <Button
          type="primary"
          onClick={handleDistribute}
          loading={loading}
          disabled={!account || !patentDetails || distributionAmount <= 0}
          style={{ width: '100%' }}
        >
          Distribute Royalties
        </Button>
      </Card>

      <Card title="Payment History" style={{ marginTop: 16 }}>
        <Table
          dataSource={patentDetails?.paymentHistory || []}
          columns={columns}
          rowKey="timestamp"
          pagination={{ pageSize: 5 }}
        />
      </Card>
    </div>
  );
};

export default RoyaltyDashboard; 