import React, { useState } from 'react';
import { Form, Input, Button, InputNumber, message, Card } from 'antd';
import { useWallet } from '@aptos-labs/wallet-adapter-react';
import { AptosClient } from '@aptos-labs/ts-sdk';

const PatentRegistrationForm: React.FC = () => {
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const { account, signAndSubmitTransaction } = useWallet();
  const aptosClient = new AptosClient('https://fullnode.testnet.aptoslabs.com/v1');

  const onFinish = async (values: any) => {
    if (!account) {
      message.error('Please connect your wallet first');
      return;
    }

    setLoading(true);
    try {
      // Prepare the transaction payload
      const payload = {
        type: "entry_function_payload",
        function: `${account.address}::patent_token::initialize`,
        type_arguments: [],
        arguments: [
          values.patentId,
          values.totalSupply,
          values.royaltyRate,
        ],
      };

      // Submit the transaction
      const response = await signAndSubmitTransaction(payload);
      await aptosClient.waitForTransaction(response.hash);

      message.success('Patent token created successfully!');
      form.resetFields();
    } catch (error) {
      console.error('Error creating patent token:', error);
      message.error('Failed to create patent token');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Card title="Register New Patent" style={{ maxWidth: 600, margin: '0 auto' }}>
      <Form
        form={form}
        layout="vertical"
        onFinish={onFinish}
        initialValues={{ royaltyRate: 5 }}
      >
        <Form.Item
          name="patentId"
          label="Patent ID"
          rules={[{ required: true, message: 'Please input the patent ID!' }]}
        >
          <Input placeholder="e.g., US12345678" />
        </Form.Item>

        <Form.Item
          name="totalSupply"
          label="Total Token Supply"
          rules={[{ required: true, message: 'Please input the total supply!' }]}
        >
          <InputNumber
            min={1}
            style={{ width: '100%' }}
            placeholder="Number of tokens to mint"
          />
        </Form.Item>

        <Form.Item
          name="royaltyRate"
          label="Royalty Rate (%)"
          rules={[{ required: true, message: 'Please input the royalty rate!' }]}
        >
          <InputNumber
            min={0}
            max={100}
            style={{ width: '100%' }}
            placeholder="Percentage of revenue to distribute"
          />
        </Form.Item>

        <Form.Item>
          <Button
            type="primary"
            htmlType="submit"
            loading={loading}
            disabled={!account}
            style={{ width: '100%' }}
          >
            {account ? 'Create Patent Token' : 'Connect Wallet to Continue'}
          </Button>
        </Form.Item>
      </Form>
    </Card>
  );
};

export default PatentRegistrationForm; 