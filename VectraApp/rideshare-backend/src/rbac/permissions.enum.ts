export type Permission =
  // rider-facing
  | 'ride:book'
  | 'profile:view'
  | 'profile:edit'
  | 'payments:view'
  | 'carbon:dashboard'
  // driver-facing
  | 'ride:accept'
  | 'ride:see_requests'
  | 'navigation:use'
  | 'earnings:view'
  | 'availability:toggle'
  // admin & community admin
  | 'user:manage'
  | 'system:config'
  | 'incident:resolve'
  | 'financial:view'
  | 'leaderboard:manage'
  // sensitive actions
  | 'fare:adjust'
  | 'user:suspend'
  | 'payout:process'
  | 'fleet:view'
  ;
