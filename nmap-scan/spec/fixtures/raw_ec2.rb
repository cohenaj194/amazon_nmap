# frozen_string_literal: true

RAW_EC2 = [
  {
    instances: [
      {
        instance_id: 'i-asdfghjkl1',
        state: {
          code: 16,
          name: 'running'
        },
        public_dns_name: 'ec2-1-1-1-1.us-west-2.compute.amazonaws.com',
        product_codes: [],
        instance_type: 'c3.large',
        placement: {
          availability_zone: 'us-west-2a',
          group_name: '',
          tenancy: 'default'
        },
        public_ip_address: '1.1.1.1',
        tags: [
          {
            key: 'Name',
            value: 'login1-green'
          },
          {
            key: 'role',
            value: 'login'
          },
          {
            key: 'color',
            value: 'green'
          }
        ]
      }
    ]
  },
  {
    instances: [
      {
        instance_id: 'i-poiuytrewq2',
        state: {
          code: 48,
          name: 'terminated'
        },
        public_dns_name: '',
        instance_type: 'r4.xlarge',
        placement: {
          availability_zone: 'us-west-2a',
          group_name: '',
          tenancy: 'default'
        },
        tags: [
          {
            key: 'color',
            value: 'red'
          },
          {
            key: 'Name',
            value: 'app5'
          }
        ]
      }
    ]
  },
  {
    instances: [
      {
        instance_id: 'i-lkjhgfds3',
        state: {
          code: 16,
          name: 'running'
        },
        public_dns_name: 'ec2-2-2-2-2.us-west-2.compute.amazonaws.com',
        instance_type: 'r4.xlarge',
        placement: {
          availability_zone: 'us-west-2a',
          group_name: '',
          tenancy: 'default'
        },
        public_ip_address: '2.2.2.2',
        tags: [
          {
            key: 'Name',
            value: 'app1-green'
          },
          {
            key: 'color',
            value: 'green'
          }
        ]
      }
    ]
  },
  {
    instances: [
      {
        instance_id: 'i-mnbvcxzzz4',
        state: {
          code: 48,
          name: 'terminated'
        },
        public_ip_address: '5.5.5.5',
        public_dns_name: '',
        instance_type: 't1.micro',
        placement: {
          availability_zone: 'us-west-2a',
          group_name: '',
          tenancy: 'default'
        },
        tags: [
          {
            key: 'Name',
            value: 'foobar'
          },
          {
            key: 'foobar',
            value: '1'
          },
          {
            key: 'color',
            value: 'red'
          },
          {
            key: 'role',
            value: 'login'
          }
        ]
      }
    ]
  }
].freeze
