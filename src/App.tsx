import React from 'react';
import { VyronProvider, useVyron } from './context/VyronContext';
import { Layout } from './components/Layout';
import { OverviewView } from './views/OverviewView';
import { BrandsView } from './views/BrandsView';
import { ProductsView } from './views/ProductsView';
import { ContentView } from './views/ContentView';
import { ChannelsView } from './views/ChannelsView';
import { AnalyticsView } from './views/AnalyticsView';
import { FinanceView } from './views/FinanceView';
import { AutomationsView } from './views/AutomationsView';
import { ActivityView } from './views/ActivityView';
import { NotificationsView } from './views/NotificationsView';
import { SettingsView } from './views/SettingsView';

const VyronWorkspace: React.FC = () => {
  const { activeModule } = useVyron();

  const renderModule = () => {
    switch (activeModule) {
      case 'overview':
        return <OverviewView />;
      case 'brands':
        return <BrandsView />;
      case 'products':
        return <ProductsView />;
      case 'content':
        return <ContentView />;
      case 'channels':
        return <ChannelsView />;
      case 'analytics':
        return <AnalyticsView />;
      case 'finance':
        return <FinanceView />;
      case 'automations':
        return <AutomationsView />;
      case 'activity':
        return <ActivityView />;
      case 'notifications':
        return <NotificationsView />;
      case 'settings':
        return <SettingsView />;
      default:
        return <OverviewView />;
    }
  };

  return <Layout>{renderModule()}</Layout>;
};

export default function App() {
  return (
    <VyronProvider>
      <VyronWorkspace />
    </VyronProvider>
  );
}
