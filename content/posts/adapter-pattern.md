+++
title = 'Keeping Integrations Manageable with the Adapter Pattern'
date = '2026-10-11'
draft = false
description = 'Using C# adapters to keep provider-specific details out of application logic, with a fictional delivery example.'
tags = ['C#', 'Architecture', 'Design Patterns']
+++

An integration often starts with a simple API call. Over time, that call brings more responsibilities: authentication, request mapping, response validation, and error handling.

While learning about integration design, one idea stood out to me: **the application should own the interface it depends on**.

The adapter pattern helps create that boundary. An adapter translates between what the application needs and how an external service works.

To explore this, let’s use a fictional delivery application.

## When provider details spread

Imagine an online store that requests a shipment when an order is ready.

Calling a delivery provider directly from the order service seems straightforward. But the provider has its own conventions:

- Addresses use particular field names.
- Tracking identifiers have provider-specific names.
- Errors follow a particular response format.

If the order service handles all of these details, it becomes responsible for both managing orders and understanding the provider’s API.

Adding another provider introduces more conditions. Changing providers—or handling an API update—can then affect business logic that should have little reason to change.

## Define what the application needs

Instead of starting with the provider’s API, we can start with the application’s requirements.

Our application needs to request a shipment and receive a tracking identifier:

```csharp
public sealed record DeliveryAddress(
    string Street,
    string PostalCode,
    string CountryCode);

public sealed record ShipmentRequest(
    string OrderId,
    DeliveryAddress Destination);

public sealed record ShipmentReceipt(string TrackingId);

public interface IShippingGateway
{
    Task<ShipmentReceipt> CreateShipmentAsync(
        ShipmentRequest request,
        CancellationToken cancellationToken = default);
}
```

`IShippingGateway` belongs to the application. Its names describe the application’s needs rather than copying a provider’s API.

The order service can depend on this interface without knowing the external endpoint or payload format.

## Translate at the boundary

Suppose a fictional provider calls shipment creation “booking a delivery” and returns a “consignment number.”

These types represent its API contract:

```csharp
public sealed record ParcelBooking(
    string Reference,
    string AddressLine,
    string Postcode,
    string Country);

public sealed record ParcelBookingResponse(
    string ConsignmentNumber);

public interface IParcelProviderClient
{
    Task<ParcelBookingResponse> BookDeliveryAsync(
        ParcelBooking booking,
        CancellationToken cancellationToken);
}
```

The adapter connects that contract to our application:

```csharp
public sealed class ParcelProviderAdapter : IShippingGateway
{
    private readonly IParcelProviderClient _client;

    public ParcelProviderAdapter(IParcelProviderClient client)
    {
        _client = client;
    }

    public async Task<ShipmentReceipt> CreateShipmentAsync(
        ShipmentRequest request,
        CancellationToken cancellationToken = default)
    {
        var booking = new ParcelBooking(
            Reference: request.OrderId,
            AddressLine: request.Destination.Street,
            Postcode: request.Destination.PostalCode,
            Country: request.Destination.CountryCode);

        var response = await _client.BookDeliveryAsync(
            booking,
            cancellationToken);

        return new ShipmentReceipt(
            TrackingId: response.ConsignmentNumber);
    }
}
```

The translation happens in two directions:

1. The application’s shipment request becomes the provider’s booking request.
2. The provider’s consignment number becomes the application’s tracking identifier.

This example focuses on that translation. A real implementation would also need validation and deliberate error handling.

The client handles the provider’s transport concerns, such as HTTP requests and authentication. The adapter handles the meaning of its inputs and outputs.

## Connect it through dependency injection

In an ASP.NET Core application, we can register the adapter:

```csharp
builder.Services.AddScoped<
    IShippingGateway,
    ParcelProviderAdapter>();
```

We must also register a concrete implementation of `IParcelProviderClient`.

Code that needs shipment creation receives `IShippingGateway` through its constructor. It does not need to choose or construct a provider adapter itself.

If the provider changes a response field, the adapter becomes the natural place to update the mapping. The order logic can stay focused on orders.

## Errors are part of the contract

Successful responses are only half of an integration.

One provider might reject an address using an HTTP status code. Another might return an error field inside an otherwise successful HTTP response.

The adapter can translate those differences into errors the application understands, such as:

- Invalid destination.
- Shipment request rejected.
- Provider temporarily unavailable.

However, translating every failure into “shipment failed” hides useful distinctions.

An invalid address needs a correction. A temporary outage might justify a retry. An unexpected response needs investigation. Those cases should not automatically produce the same behavior.

It is also useful to retain the original cause for diagnostics, while keeping credentials and sensitive payloads out of logs.

## An adapter does not make retries safe

Consider a request that times out after it reaches the provider.

The provider might have created the shipment even though our application never received the response. Retrying could create another shipment.

Putting the API call behind an adapter does not remove that uncertainty.

Safe retry behavior may require:

- A provider-supported idempotency key.
- A way to look up the original request.
- A reconciliation process for uncertain outcomes.

An order identifier is not automatically an idempotency key. The provider must explicitly support the required duplicate-prevention behavior.

This is a useful reminder that the interface needs to describe meaningful guarantees. A method signature alone cannot tell us whether retrying is safe.

## Test each side of the boundary

The interface makes application tests easier to isolate.

For example, an order-service test can use a fake `IShippingGateway` that returns a tracking identifier or simulates a failure. We can then check how the order service responds without contacting a real provider.

The adapter needs different tests:

- Does it map address fields correctly?
- Does it preserve the request reference?
- Does it return the expected tracking identifier?
- Does it translate known errors correctly?
- Does it handle an unexpected response?

A fake gateway helps validate business behavior. Adapter tests validate translation. Neither proves that the live provider still behaves as expected, so a sandbox integration check can add confidence.

## Keep meaningful differences visible

A common interface is useful only when its promises are realistic.

Suppose one provider supports cancellation after booking and another does not. Adding `CancelShipmentAsync()` to every implementation could create an interface that some providers cannot honestly support.

A separate capability interface may be clearer:

```csharp
public interface IShipmentCancellationGateway
{
    Task CancelShipmentAsync(
        string trackingId,
        CancellationToken cancellationToken = default);
}
```

Providers that support cancellation can implement this additional contract. The application still needs a deliberate way to select and use that capability.

The aim is to reduce unnecessary coupling while preserving differences that affect behavior.

## What I learned

The main lesson for me is that an adapter should do more than wrap an API client. It should establish a clear boundary between the application’s model and an external system’s model.

Before designing that boundary, I would ask:

- What behavior does the application actually need?
- Which details belong to the provider?
- Which differences must remain visible?
- What happens when the outcome of a request is uncertain?

Those questions make the abstraction more useful.

External services evolve independently. A well-designed adapter gives provider-specific changes a defined place to land—and keeps the application easier to understand.
