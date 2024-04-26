import { registerPlugin } from '@capacitor/core';

import type { ScApplePayPlugin } from './definitions';

const ScApplePay = registerPlugin<ScApplePayPlugin>('ScApplePay', {
  web: () => import('./web').then(m => new m.ScApplePayWeb()),
});

export * from './definitions';
export { ScApplePay };
