import React, { useState } from 'react';
import { Layout, Tabs } from 'antd';
import PatentRegistration from '../components/PatentRegistration';
import RoyaltyDashboard from '../components/RoyaltyDashboard';
import GovernanceInterface from '../components/GovernanceInterface';

const { Header, Content } = Layout;
const { TabPane } = Tabs;

const HomePage: React.FC = () => {
  const [activeTab, setActiveTab] = useState('1');

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Header style={{ background: '#fff', padding: '0 20px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h1>IP Fractionizer</h1>
          <button onClick={() => window.aptos?.connect()}>Connect Wallet</button>
        </div>
      </Header>
      <Content style={{ padding: '20px' }}>
        <Tabs activeKey={activeTab} onChange={setActiveTab}>
          <TabPane tab="Patent Registration" key="1">
            <PatentRegistration />
          </TabPane>
          <TabPane tab="Royalty Dashboard" key="2">
            <RoyaltyDashboard />
          </TabPane>
          <TabPane tab="Governance" key="3">
            <GovernanceInterface />
          </TabPane>
        </Tabs>
      </Content>
    </Layout>
  );
};

export default HomePage; 