import React, { useState, useEffect } from 'react';
import { Card, Table, Button, Input, Select, message, Modal, Progress, Tag } from 'antd';
import { useWallet } from '@aptos-labs/wallet-adapter-react';
import { AptosClient } from '@aptos-labs/ts-sdk';
import { NODE_URL } from '../config/constants';

const { TextArea } = Input;
const { Option } = Select;

interface Proposal {
  id: number;
  creator: string;
  patentId: string;
  type: number;
  description: string;
  startTime: number;
  endTime: number;
  status: number;
  yesVotes: number;
  noVotes: number;
}

const GovernanceInterface: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [proposals, setProposals] = useState<Proposal[]>([]);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [newProposal, setNewProposal] = useState({
    type: 1,
    description: '',
  });
  const { account, signAndSubmitTransaction } = useWallet();
  const aptosClient = new AptosClient(NODE_URL);

  useEffect(() => {
    if (account) {
      fetchProposals();
    }
  }, [account]);

  const fetchProposals = async () => {
    try {
      const resource = await aptosClient.getAccountResource(
        account!.address,
        `${account!.address}::governance::GovernanceState`
      );

      const proposalsData = resource.data.proposals.map((proposal: any) => ({
        id: Number(proposal.id),
        creator: proposal.creator,
        patentId: proposal.patent_id,
        type: Number(proposal.proposal_type),
        description: proposal.description,
        startTime: Number(proposal.start_time),
        endTime: Number(proposal.end_time),
        status: Number(proposal.status),
        yesVotes: Number(proposal.yes_votes),
        noVotes: Number(proposal.no_votes),
      }));

      setProposals(proposalsData);
    } catch (error) {
      console.error('Error fetching proposals:', error);
      message.error('Failed to fetch proposals');
    }
  };

  const handleCreateProposal = async () => {
    if (!account || !newProposal.description) return;

    setLoading(true);
    try {
      const payload = {
        type: "entry_function_payload",
        function: `${account.address}::governance::create_proposal`,
        type_arguments: [],
        arguments: [
          proposals[0]?.patentId || '', // Using first proposal's patent ID as example
          newProposal.type.toString(),
          newProposal.description,
        ],
      };

      const response = await signAndSubmitTransaction(payload);
      await aptosClient.waitForTransaction(response.hash);

      message.success('Proposal created successfully!');
      setIsModalVisible(false);
      setNewProposal({ type: 1, description: '' });
      fetchProposals();
    } catch (error) {
      console.error('Error creating proposal:', error);
      message.error('Failed to create proposal');
    } finally {
      setLoading(false);
    }
  };

  const handleVote = async (proposalId: number, voteYes: boolean) => {
    if (!account) return;

    setLoading(true);
    try {
      const payload = {
        type: "entry_function_payload",
        function: `${account.address}::governance::vote`,
        type_arguments: [],
        arguments: [
          proposals[0]?.patentId || '', // Using first proposal's patent ID as example
          proposalId.toString(),
          voteYes,
        ],
      };

      const response = await signAndSubmitTransaction(payload);
      await aptosClient.waitForTransaction(response.hash);

      message.success(`Vote ${voteYes ? 'for' : 'against'} recorded successfully!`);
      fetchProposals();
    } catch (error) {
      console.error('Error voting:', error);
      message.error('Failed to record vote');
    } finally {
      setLoading(false);
    }
  };

  const getProposalType = (type: number) => {
    switch (type) {
      case 1: return 'License';
      case 2: return 'Royalty';
      case 3: return 'Transfer';
      default: return 'Unknown';
    }
  };

  const getStatusTag = (status: number) => {
    switch (status) {
      case 1: return <Tag color="blue">Active</Tag>;
      case 2: return <Tag color="green">Passed</Tag>;
      case 3: return <Tag color="red">Rejected</Tag>;
      default: return <Tag>Unknown</Tag>;
    }
  };

  const columns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
    },
    {
      title: 'Type',
      dataIndex: 'type',
      key: 'type',
      render: (type: number) => getProposalType(type),
    },
    {
      title: 'Description',
      dataIndex: 'description',
      key: 'description',
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (status: number) => getStatusTag(status),
    },
    {
      title: 'Votes',
      key: 'votes',
      render: (record: Proposal) => (
        <div>
          <Progress
            percent={Math.round((record.yesVotes / (record.yesVotes + record.noVotes)) * 100)}
            format={(percent) => `${percent}% Yes`}
          />
          <div style={{ marginTop: 8 }}>
            <Button
              type="primary"
              onClick={() => handleVote(record.id, true)}
              disabled={record.status !== 1}
            >
              Vote Yes
            </Button>
            <Button
              danger
              onClick={() => handleVote(record.id, false)}
              disabled={record.status !== 1}
              style={{ marginLeft: 8 }}
            >
              Vote No
            </Button>
          </div>
        </div>
      ),
    },
  ];

  return (
    <div style={{ maxWidth: 1200, margin: '0 auto' }}>
      <Card
        title="Governance Proposals"
        extra={
          <Button type="primary" onClick={() => setIsModalVisible(true)}>
            Create Proposal
          </Button>
        }
      >
        <Table
          dataSource={proposals}
          columns={columns}
          rowKey="id"
          pagination={{ pageSize: 5 }}
        />
      </Card>

      <Modal
        title="Create New Proposal"
        visible={isModalVisible}
        onOk={handleCreateProposal}
        onCancel={() => setIsModalVisible(false)}
        confirmLoading={loading}
      >
        <Select
          style={{ width: '100%', marginBottom: 16 }}
          value={newProposal.type}
          onChange={(value) => setNewProposal({ ...newProposal, type: value })}
        >
          <Option value={1}>License</Option>
          <Option value={2}>Royalty</Option>
          <Option value={3}>Transfer</Option>
        </Select>
        <TextArea
          rows={4}
          placeholder="Enter proposal description"
          value={newProposal.description}
          onChange={(e) => setNewProposal({ ...newProposal, description: e.target.value })}
        />
      </Modal>
    </div>
  );
};

export default GovernanceInterface; 