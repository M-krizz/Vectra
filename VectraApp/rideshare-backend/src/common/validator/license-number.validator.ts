import { registerDecorator, ValidationOptions, ValidationArguments } from 'class-validator';

/**
 * Example very simple Indian license regex: 2 letters + 2 digits + 11 chars... (adjust to local rules).
 * Use a robust regex for production or plug an external lib/service if license formats vary by country.
 */
export function IsLicenseNumber(validationOptions?: ValidationOptions) {
  return function (object: Object, propertyName: string) {
    registerDecorator({
      name: 'isLicenseNumber',
      target: object.constructor,
      propertyName,
      options: validationOptions,
      validator: {
        validate(value: any, args: ValidationArguments) {
          if (!value) return false;
          // simple allowed chars check (alphanumeric + / -)
          return /^[A-Z0-9\-\/]{5,25}$/i.test(value);
        },
      },
    });
  };
}
