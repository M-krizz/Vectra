import {
  registerDecorator,
  ValidationOptions,
  ValidationArguments,
} from 'class-validator';

export function IsEmailOrPhone(validationOptions?: ValidationOptions) {
  return function (object: Object, propertyName: string) {
    registerDecorator({
      name: 'isEmailOrPhone',
      target: object.constructor,
      propertyName,
      options: validationOptions,
      validator: {
        validate(_: any, args: ValidationArguments) {
          const obj = args.object as any;
          const hasEmail =
            obj.email !== undefined && obj.email !== null && obj.email !== '';
          const hasPhone =
            obj.phone !== undefined && obj.phone !== null && obj.phone !== '';
          return hasEmail || hasPhone;
        },
        defaultMessage() {
          return 'Either email or phone must be provided';
        },
      },
    });
  };
}
